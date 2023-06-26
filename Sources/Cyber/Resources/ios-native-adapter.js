(() => {
class iOSNativeAdapter {
	constructor() {
		this.messageHandler = webkit.messageHandlers.Cyber
	}

    setAdapter() {
		if (window.Cyber) {
			window.Cyber.nativeAdapter = this
		} else {
			throw new Error("Failed to register the iOSNativeAdapter")
		}
    }
    
	dispatchToNative(name, data = {}) {
		data["timestamp"] = Date.now()
		this.messageHandler.postMessage({ name: name, data: data })
	}
	
    dispatchToScript(name, data = {}) {
		window.Cyber.dispatchToScript(name, data)
	}

	pageLoaded() {
		this.dispatchToNative("pageLoaded")
	}

	pageLoadFailed() {
		this.dispatchToNative("pageLoadFailed")
	}

    errorRaised(error) {
		this.dispatchToNative("errorRaised", { error: error })
    }
}

addEventListener("error", event => {
	const error = event.message + " (" + event.filename + ":" + event.lineno + ":" + event.colno + ")"
	window.CyberNativeAdapter.errorRaised(error)
}, false)

window.CyberNativeAdapter = new iOSNativeAdapter()

const setup = function() {
	window.CyberNativeAdapter.setAdapter()
	window.CyberNativeAdapter.pageLoaded()

	document.removeEventListener("Cyber:load", setup)
}

const setupOnLoad = () => {
	const Cyber_LOAD_TIMEOUT = 2000

	document.addEventListener("Cyber:load", setup)

	setTimeout(() => {
		if (!window.Cyber) {
			window.CyberNativeAdapter.pageLoadFailed()
		}
	}, Cyber_LOAD_TIMEOUT)
}

if (window.Cyber) {
	setup()
} else {
	setupOnLoad()
}
})()

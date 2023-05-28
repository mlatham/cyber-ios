(() => {
class iOSNativeAdapter {
	constructor() {
		this.messageHandler = webkit.messageHandlers.crux
	}

    setAdapter() {
		if (window.Crux) {
			window.Crux.nativeAdapter = this
		} else {
			throw new Error("Failed to register the iOSNativeAdapter")
		}
    }
    
	dispatchToNative(name, data = {}) {
		data["timestamp"] = Date.now()
		this.messageHandler.postMessage({ name: name, data: data })
	}
	
    dispatchToScript(name, data = {}) {
		window.Crux.dispatchToScript(name, data)
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
	window.CruxNativeAdapter.errorRaised(error)
}, false)

window.CruxNativeAdapter = new iOSNativeAdapter()

const setup = function() {
	window.CruxNativeAdapter.setAdapter()
	window.CruxNativeAdapter.pageLoaded()

	document.removeEventListener("crux:load", setup)
}

const setupOnLoad = () => {
	const CRUX_LOAD_TIMEOUT = 2000

	document.addEventListener("crux:load", setup)

	setTimeout(() => {
		if (!window.Crux) {
			window.CruxNativeAdapter.pageLoadFailed()
		}
	}, CRUX_LOAD_TIMEOUT)
}

if (window.Crux) {
	setup()
} else {
	setupOnLoad()
}
})()

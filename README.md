# Cyber-iOS

A description of this package.


### Setup

Add the `dist` folder into the bundle. Make sure you select "Create folder references for any added folders option when copying".


### Initializing 

```
import Cyber

// Configures where to find html content.
let config = BridgeConfiguration(
	routes: [ "*" ],
	localBaseURL: "dist")

// Creates middleware.
config.middlewares.add(NavigationMiddleware(config))
config.middlewares.add(LoggingMiddleware())

BridgeConfiguration.defaultConfiguration = config

let webViewController = WebViewController("index")
webViewController.dispatch(Message(name: "navigate", data: ["to": "profile"])
```

### Bridge Configuration

Explicit routes:

```
let config = BridgeCpnfiguration(
	routes: [
		"profile",
		"discover",
		"settings"
	],
	localBaseURL: "dist")
```

Route for each .html file in the embedded `dist` folder:

```
let config = BridgeCpnfiguration(
	routes: [ "*" ],
	localBaseURL: "dist")
```

Route for each file matching a glob pattern in the embedded `dist` folder:

```
let config = BridgeCpnfiguration(
	routes: [ "*.html" ],
	localBaseURL: "dist")
```

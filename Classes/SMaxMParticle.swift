//
//  SMaxMParticle
//  SMaxMParticle
//
//  Created by Mohieddine Zarif on 04/06/2020.
//  Copyright © 2020 CME. All rights reserved.
//

import ZappPlugins
import ZappAnalyticsPluginsSDK
import mParticle_BranchMetrics


open class SMaxMParticle: ZPAnalyticsProvider, ZPPlayerAnalyticsProviderProtocol {

    public let MAX_PARAM_NAME_CHARACTERS_LONG  :Int = 40
    public let MAX_PARAM_VALUE_CHARACTERS_LONG :Int = 100
    public let FIREBASE_PREFIX : String = "Firebase_"
    public let APPLICASTER_PREFIX : String = "applicaster_"
    private var LEGENT : Dictionary<String, String> = [:]
    private var LEGENT_JSON : String = "{\" \":\"__\",\"_\":\"_0\",\"-\":\"_1\",\":\":\"_2\",\"'\":\"_3\",\".\":\"_4\",\",\":\"_5\",\"/\":\"_6\",\"\\\\\":\"_7\",\"(\":\"_8\",\")\":\"_A\",\"?\":\"_B\",\"\\\"\":\"_C\",\"!\":\"_D\",\"@\":\"_E\",\"#\":\"_F\",\"$\":\"_G\",\"%\":\"_H\",\"^\":\"_I\",\"&\":\"_J\",\"*\":\"_K\",\"=\":\"_M\",\"+\":\"_N\",\"~\":\"_L\",\"`\":\"_O\",\"|\":\"_P\",\";\":\"_Q\",\"[\":\"_R\",\"]\":\"_S\",\"}\":\"_T\",\"{\":\"_U\"}"
    
    fileprivate let video_prefix = "(VOD)"
    fileprivate let video_play_event = "VOD Item: Play was Triggered"
    fileprivate let item_name_key = "Item Name"
    let eventDuration = "EVENT_DURATION"
    fileprivate let MPARTCILE_KEY = "mparticle_key"
    fileprivate let MPARTICLE_SECRET = "mparticle_secret"
    fileprivate let SCREEN_VISIT_KEY = "screen_visit"
    static var isAutoIntegrated: Bool = false
    var timedEventDictionary: NSMutableDictionary?

    lazy var blacklistedEvents:[String] = {
        if let events = self.configurationJSON?["blacklisted_events"] as? String {
            return events.components(separatedBy: ";").filter { $0.isEmpty == false }.map { $0.lowercased() }
        }
        else {
            return []
        }
    }()

    
    var isUserProfileEnabled = true
    
    //Firebase User Profile
    struct UserProfile {
        static let created = "$created"
        static let iOSDevices = "$ios_devices"
    }
    
    //Json Keys
    struct JsonKeys {
        static let sendUserData = "Send_User_Data"
    }
    
    public required init() {
        super.init()
        self.configurationJSON = configurationJSON
    }

    public required init(configurationJSON: NSDictionary?) {
        super.init()
        self.configurationJSON = configurationJSON
    }

    
    public override func createAnalyticsProvider(_ allProvidersSetting: [String : NSObject]) -> Bool {
        return super.createAnalyticsProvider(allProvidersSetting)
    }
    
    override open func getKey() -> String {
        return "branchMParticle"
    }
    
    
    override open func configureProvider() -> Bool {
        if !(SMaxMParticle.isAutoIntegrated) {
            self.setupMParticle()
        }
        return SMaxMParticle.isAutoIntegrated
    }
    
    fileprivate func setupMParticle() {
        if let mParticleProdKey = self.configurationJSON?[self.MPARTCILE_KEY] as? String,
            let mParticleProdSecret = self.configurationJSON?[self.MPARTICLE_SECRET] as? String {
                let options = MParticleOptions(key: mParticleProdKey,
                                                     secret: mParticleProdSecret)
                
                let identityRequest = MPIdentityApiRequest.init()
                
                options.identifyRequest = identityRequest

                #if PROD
                options.environment = MPEnvironment.production
                #else
                options.environment = MPEnvironment.development
                #endif
                
                MParticle.sharedInstance().start(with: options)
                SMaxMParticle.isAutoIntegrated = true
        }

    }
    
    override open func trackEvent(_ eventName: String, parameters: [String : NSObject], completion: ((Bool, String?) -> Void)?) {
        super.trackEvent(eventName, parameters: parameters)
        var combinedParameters = ZPAnalyticsProvider.defaultProperties(self.defaultEventProperties, combinedWithEventParams: parameters)

        let eventName = refactorParamName(eventName: eventName)
        let event = MPEvent(name: eventName, type: MPEventType.navigation)
        
        if combinedParameters.isEmpty == true {
            event?.customAttributes = nil
        }
        else {
            combinedParameters = refactorEventParameters(parameters: combinedParameters)
            event?.customAttributes = combinedParameters
        }
        
        if (event != nil) {
            MParticle.sharedInstance().logEvent(event!)
        }
    }

    public override func shouldTrackEvent(_ eventName: String) -> Bool {
        return true
    }
    
    override open func trackEvent(_ eventName:String, parameters:[String:NSObject]) {
        super.trackEvent(eventName, parameters: parameters)
        var combinedParameters = ZPAnalyticsProvider.defaultProperties(self.defaultEventProperties, combinedWithEventParams: parameters)

        let eventName = refactorParamName(eventName: eventName)
        let event = MPEvent(name: eventName, type: MPEventType.navigation)
        
        if combinedParameters.isEmpty == true {
            event?.customAttributes = nil
        }
        else {
            combinedParameters = refactorEventParameters(parameters: combinedParameters)
            event?.customAttributes = combinedParameters
        }
        
        if (event != nil) {
            MParticle.sharedInstance().logEvent(event!)
        }
    }

    open func trackEvent(_ eventName:String, parameters:[String:NSObject], model: Any?) {
        trackEvent(eventName, parameters: parameters)
    }
    
    override open func trackEvent(_ eventName:String, action:String, label:String, value:Int) {
        
    }
    
    public func startStreaming(withURL url: URL) {
        
    }

    override open func trackEvent(_ eventName:String, message: String, exception:NSException) {
        trackEvent(eventName, parameters: [String : NSObject]())
    }
    
    override open func trackEvent(_ eventName:String, message: String, error: NSError) {
        trackEvent(eventName, parameters: [String : NSObject]())

    }
    
    override open func trackEvent(_ eventName:String, timed:Bool) {
        if timed {
            registerTimedEvent(eventName, parameters: nil)
        } else {
            trackEvent(eventName, parameters: [String : NSObject]())
        }
    }
    
    override open func trackEvent(_ eventName:String, parameters: [String:NSObject], timed:Bool) {
        if timed {
            registerTimedEvent(eventName, parameters: parameters)
        } else {
            trackEvent(eventName, parameters: parameters)
        }
    }
    
    override open func trackEvent(_ eventName: String) {
        trackEvent(eventName, parameters: [String : NSObject]())
    }
    
    override open func endTimedEvent(_ eventName: String, parameters: [String : NSObject]) {
        if let timedEventDictionary = timedEventDictionary {
            if let startDate = timedEventDictionary[eventName] as? Date {
                let endDate = Date()
                let elapsed = endDate.timeIntervalSince(startDate)
                var params = parameters.count > 0 ? parameters : [String : NSObject]()
                let durationInMilSec = NSString(format:"%f",elapsed * 1000)
                params[eventDuration] = durationInMilSec
                trackEvent(eventName, parameters: params)
            }
        }
    }
    
    override open func setUserProfile(genericUserProperties dictGenericUserProperties: [String : NSObject],
                                      piiUserProperties dictPiiUserProperties: [String : NSObject]) {
        if isUserProfileEnabled {
            var mParticleParameters = [String : NSObject]()
            for (key, value) in dictGenericUserProperties {
                switch key {
                case kUserPropertiesCreatedKey:
                    mParticleParameters[UserProfile.created] = value
                case kUserPropertiesiOSDevicesKey:
                    mParticleParameters[UserProfile.iOSDevices] = value
                default:
                    mParticleParameters[key] = value
                }
            }
            
            // TODO: update user identity
        }
    }
    
    public override func trackScreenView(_ screenName: String, parameters: [String : NSObject]) {
        let eventName = self.SCREEN_VISIT_KEY
        trackEvent(eventName, parameters: parameters)
    }
    
    public func startTrackingPlayerEvents(forPlayer player: Any) {
    }
    
    /*
     * loading LEGENT Dictionary according LEGENT_JSON
     */
    public func initLegent() {
        LEGENT = convertToDictionary(jsonString: LEGENT_JSON)
    }
    
    /**
     * @param eventValue the text we should encode according param value limitations.
     * @return encoded string base on eventValue
     * @discussion  Firebase param value limitations:
     * @discussion  **********************
     * @discussion  1. Param values can be up to 100 characters long.
     * @discussion  2. The "firebase_" prefix is reserved and should not be used so APPLICASTER_PREFIX will be added.
     */
    public func  refactorParamValue(eventValue:  String) -> String{
        var returnValue:String = eventValue
        
        if (returnValue.hasPrefix(FIREBASE_PREFIX)) {
            returnValue = APPLICASTER_PREFIX + returnValue;
        }
        
        //Param values can be up to 100 characters long.
        if (returnValue.count > MAX_PARAM_VALUE_CHARACTERS_LONG) {
            returnValue = String(returnValue[returnValue.startIndex..<returnValue.index(returnValue.startIndex, offsetBy: MAX_PARAM_VALUE_CHARACTERS_LONG)])
        }
        
        return returnValue;
    }
    
    /*
     * @param eventValue the text we should encode according param name limitations.
     * @return encoded string base on eventName
     * @discussion  Firebase param names limitations:
     * @discussion  **********************
     * @discussion  1. Param names can be up to 40 characters long.
     * @discussion  2. Contain alphanumeric characters and underscores ("_").
     * @discussion  3. must start with an alphabetic character.
     * @discussion  4. The "firebase_" prefix is reserved and should not be used so APPLICASTER_PREFIX will be added.
     */
    public func refactorParamName( eventName: String) -> String {
        var returnValue:String = eventName
        //Contain alphanumeric characters and underscores ("_").
        returnValue = recursiveEncodeAlphanumericCharacters(eventName: returnValue)
        
        if (returnValue.hasPrefix(FIREBASE_PREFIX)) {
            returnValue = APPLICASTER_PREFIX + returnValue
        }
        
        // 3. must start with an alphabetic chaacter.
        if returnValue.isEmpty == false {
            switch returnValue[returnValue.startIndex] {
            case "0"..."9" , "a"..."z", "A"..."Z":
                break
            default:
                returnValue = APPLICASTER_PREFIX + returnValue;
                break
            }
        }
        
        //Param names can be up to 40 characters long.
        if (returnValue.count > MAX_PARAM_NAME_CHARACTERS_LONG) {
            returnValue = String(returnValue[returnValue.startIndex..<returnValue.index(returnValue.startIndex, offsetBy: MAX_PARAM_NAME_CHARACTERS_LONG)])
        }
        
        returnValue = returnValue.replacingOccurrences(of: " ", with: "_")
        returnValue = returnValue.replacingOccurrences(of: ":", with: "")

        return returnValue;
    }
    
    /*
     * Convert json string to dictionary
     */
    private func convertToDictionary(jsonString: String) -> [String: String] {
        guard let data = jsonString.data(using: String.Encoding.utf8) else {
            return [:]
        }
        
        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: [] ) as! [String: String] else {
            return [:]
        }
        
        return jsonDictionary
    }
    
    /*
     * This function replace all the forbidden charcters with new one, according the legend dictionary.
    */
    private func recursiveEncodeAlphanumericCharacters( eventName: String ) -> String {
        let name:String = eventName
        if name.count > 0 {
            let send = name.index(name.startIndex, offsetBy: 1)
            let sendvalue = String(name[send..<name.endIndex])
            if let prefix = LEGENT[name.mParticleGetFirstCharacter! as String] {
                return prefix + recursiveEncodeAlphanumericCharacters( eventName: sendvalue)
            }else{
                return name.mParticleGetFirstCharacter! + recursiveEncodeAlphanumericCharacters( eventName: sendvalue)
            }
        }
        return ""
    }
    
    /*
     * Validate and refactor parameters before sending event
     */
    public func refactorEventParameters(parameters: [String: NSObject]) -> [String: NSObject]{
        var validateParameters = [String: NSObject]()
        for (key, value) in parameters {
            let validateParamName = refactorParamName(eventName:key)
            var validateParamValue = value
            if ((value as? String) != nil){
                validateParamValue = refactorParamValue(eventValue:value as! String) as NSObject
            }
            validateParameters[validateParamName] = validateParamValue
        }
        return validateParameters
    }
    
    public func setUserProfileWithGenericUserProperties(genericUserProperties: [String : NSObject],
                                                        piiUserProperties: [String : NSObject]) {
        
    }
    
    public override func setPushNotificationDeviceToken(_ deviceToken: Data) {
        super.setPushNotificationDeviceToken(deviceToken)
    }
    
}

// TODO: Create a plugin for all extensions and utitlies
extension String {
    public var mParticleGetFirstCharacter: String? {
        guard 0 < self.count else { return "" }
        let idx = index(startIndex, offsetBy: 0)
        return String(self[idx...idx])
    }
}

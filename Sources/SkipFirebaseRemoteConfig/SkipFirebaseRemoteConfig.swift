// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if SKIP
import Foundation
import SkipFirebaseCore
import kotlinx.coroutines.tasks.await

public final class RemoteConfig: KotlinConverting<com.google.firebase.remoteconfig.FirebaseRemoteConfig> {
    public let remoteconfig: com.google.firebase.remoteconfig.FirebaseRemoteConfig

    public init(remoteconfig: com.google.firebase.remoteconfig.FirebaseRemoteConfig) {
        self.remoteconfig = remoteconfig
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.google.firebase.remoteconfig.FirebaseRemoteConfig {
        remoteconfig
    }
    
    public static func remoteConfig() -> RemoteConfig {
        RemoteConfig(remoteconfig: com.google.firebase.remoteconfig.FirebaseRemoteConfig.getInstance())
    }

    public static func remoteConfig(app: FirebaseApp) -> RemoteConfig {
        RemoteConfig(remoteconfig: com.google.firebase.remoteconfig.FirebaseRemoteConfig.getInstance(app.app))
    }
  
    public func fetch(_ minimumFetchIntervalInSeconds:Int64) async {
        remoteconfig.fetch(minimumFetchIntervalInSeconds)
    }
    
    public func activate() async {
        let result = remoteconfig.activate().await()
    }
    
    public func fetchAndActivate() async throws {
        //let log = Logger(subsystem: "com.stalefish.MusterDev", category: "MusterLog")
        try remoteconfig.fetchAndActivate().await()
    }
    
    public func keys(withPrefix:String) -> Set<String> {
        return Set<String>(remoteconfig.getKeysByPrefix(withPrefix))
    }

    public func addOnConfigUpdateListener(_ listener: @escaping (RemoteConfigUpdate?, Error?) -> Void) -> ConfigUpdateListenerRegistration {
        var callbacks = ConfigUpdateListener()
        callbacks.callback = listener
        let lissen = remoteconfig.addOnConfigUpdateListener(callbacks)
        return ConfigUpdateListenerRegistration(reg: lissen)
    }
    
    public func string(forKey key: String) -> String? {
       return self.remoteconfig.getString(key)
    }
}

public class RemoteConfigUpdate {
    public let updatedKeys: Set<String>
    
    init(updatedKeys: Set<String>) {
        self.updatedKeys = updatedKeys
    }
}

class ConfigUpdateListener : com.google.firebase.remoteconfig.ConfigUpdateListener{

    init(){}
    
    var callback: ((RemoteConfigUpdate?, Error?) -> Void)?
    
    override func onError(_ error:  com.google.firebase.remoteconfig.FirebaseRemoteConfigException) {
        var err: Error?
        if let e = error {
            err = asNSError(firebaseRemoteConfigException: error)
        }
        Task { @MainActor in
            self.callback?(nil, err)
        }
    }
    

    override func onUpdate(_ config: com.google.firebase.remoteconfig.ConfigUpdate) {
        let update = RemoteConfigUpdate(updatedKeys: Set<String>(config.getUpdatedKeys()))
        Task { @MainActor in
            self.callback?(update, nil)
        }
    }
}

public class ConfigUpdateListenerRegistration : KotlinConverting<com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration> {
    public let reg: com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration
    
    public init(reg: com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration) {
        self.reg = reg
    }
    
    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration {
        reg
    }
    
    public var description: String {
        reg.toString()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reg == rhs.reg
    }

    public func remove() {
        reg.remove()
    }
}

public let FirestoreErrorDomain = "FIRFirestoreErrorDomain"

fileprivate func asNSError(firebaseRemoteConfigException: com.google.firebase.remoteconfig.FirebaseRemoteConfigException) -> Error {
    let userInfo: [String: Any] = [:]
    if let detailMessage = firebaseRemoteConfigException.message {
        userInfo[NSLocalizedFailureReasonErrorKey] = detailMessage
    }
    return NSError(domain: FirestoreErrorDomain, code: firebaseRemoteConfigException.code.value(), userInfo: userInfo)
}

#endif
#endif

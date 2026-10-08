import Foundation

enum AppConfig {
    /// No bundle ID was provided, so this uses the GitHub username.
    /// Change it here, in project.yml, and in both entitlements files together.
    static let bundleIdentifier = "com.aauthorizedd.hourback"
    static let appGroupIdentifier = "group.com.aauthorizedd.hourback"

    /// Shown when emergency unlocks run out. Replace before shipping.
    static let supportEmail = "support@REPLACE_ME"

    static let maxPairedTags = 3
    static let maxBlockedApps = 50
    static let lifetimeEmergencyUnlocks = 5
    static let scanPrompt = "Hold your iPhone near your HourBack tag."
}

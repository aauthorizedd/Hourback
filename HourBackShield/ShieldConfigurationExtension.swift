import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        HourBackShieldStyle.make()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        HourBackShieldStyle.make()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        HourBackShieldStyle.make()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        HourBackShieldStyle.make()
    }
}

private enum HourBackShieldStyle {
    static func make() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: .black,
            icon: nil,
            title: ShieldConfiguration.Label(text: "HourBack", color: .white),
            subtitle: ShieldConfiguration.Label(text: "This app is blocked. Scan your tag to unlock.", color: .white),
            primaryButtonLabel: nil,
            primaryButtonBackgroundColor: nil,
            secondaryButtonLabel: nil
        )
    }
}

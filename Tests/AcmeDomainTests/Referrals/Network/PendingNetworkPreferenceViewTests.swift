@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingNetworkPreference("code-85", title: "title-701")
        let view = Referrals.toPendingNetworkPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingNetworkPreferenceViews([item, item]).count == 2)
    }
}

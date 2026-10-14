@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkPreference("code-806", label: "label-272")
        let view = Referrals.toNetworkPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkPreferenceViews([item, item]).count == 2)
    }
}

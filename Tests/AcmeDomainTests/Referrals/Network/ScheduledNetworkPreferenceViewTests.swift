@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledNetworkPreference("code-337", name: "name-221")
        let view = Referrals.toScheduledNetworkPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledNetworkPreferenceViews([item, item]).count == 2)
    }
}

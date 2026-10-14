@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkEntry("code-270", name: "name-155")
        let view = Referrals.toNetworkEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkEntryViews([item, item]).count == 2)
    }
}

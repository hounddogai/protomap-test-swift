@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualNetworkNotice("code-18", name: "name-434")
        let view = Referrals.toManualNetworkNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualNetworkNoticeViews([item, item]).count == 2)
    }
}

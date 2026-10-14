@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkRecord("code-551", name: "name-270")
        let view = Referrals.toNetworkRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkRecordViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalNetworkRecord("code-929", label: "label-961")
        let view = Referrals.toGlobalNetworkRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalNetworkRecordViews([item, item]).count == 2)
    }
}

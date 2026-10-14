@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureBatch("code-858", label: "label-812")
        let view = Referrals.toClosureBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureBatchViews([item, item]).count == 2)
    }
}

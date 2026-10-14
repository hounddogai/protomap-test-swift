@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureQuota("code-435", title: "title-616")
        let view = Referrals.toClosureQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureQuotaViews([item, item]).count == 2)
    }
}

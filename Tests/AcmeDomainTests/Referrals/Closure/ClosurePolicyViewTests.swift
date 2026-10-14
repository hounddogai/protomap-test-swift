@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        let view = Referrals.toClosurePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosurePolicyViews([item, item]).count == 2)
    }
}

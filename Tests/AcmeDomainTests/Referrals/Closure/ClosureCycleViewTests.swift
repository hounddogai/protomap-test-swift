@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureCycle("code-383", label: "label-430")
        let view = Referrals.toClosureCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureCycleViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureBundle("code-285", title: "title-726")
        let view = Referrals.toClosureBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureBundleViews([item, item]).count == 2)
    }
}

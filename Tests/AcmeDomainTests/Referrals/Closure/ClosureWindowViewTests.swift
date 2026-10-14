@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureWindow("code-899", label: "label-527")
        let view = Referrals.toClosureWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureWindowViews([item, item]).count == 2)
    }
}

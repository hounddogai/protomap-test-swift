@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureProfile("code-567", title: "title-73")
        let view = Referrals.toClosureProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureProfileViews([item, item]).count == 2)
    }
}

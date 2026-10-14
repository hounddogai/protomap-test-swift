@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureGroup("code-441", title: "title-394")
        let view = Referrals.toClosureGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureGroupViews([item, item]).count == 2)
    }
}

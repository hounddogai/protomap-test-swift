@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureDraft("code-222", name: "name-597")
        let view = Referrals.toClosureDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureDraftViews([item, item]).count == 2)
    }
}

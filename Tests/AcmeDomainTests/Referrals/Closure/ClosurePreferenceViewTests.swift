@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosurePreference("code-255", title: "title-703")
        let view = Referrals.toClosurePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosurePreferenceViews([item, item]).count == 2)
    }
}

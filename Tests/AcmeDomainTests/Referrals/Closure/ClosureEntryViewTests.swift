@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureEntry("code-87", label: "label-24")
        let view = Referrals.toClosureEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureEntryViews([item, item]).count == 2)
    }
}

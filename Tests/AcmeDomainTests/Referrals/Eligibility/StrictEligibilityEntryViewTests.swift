@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilityEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictEligibilityEntry("code-15", title: "title-359")
        let view = Referrals.toStrictEligibilityEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictEligibilityEntryViews([item, item]).count == 2)
    }
}

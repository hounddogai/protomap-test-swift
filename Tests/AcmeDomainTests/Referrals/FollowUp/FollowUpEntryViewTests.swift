@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpEntry("code-502", name: "name-507")
        let view = Referrals.toFollowUpEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpEntryViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newScheduledFollowUpDraft("code-445", label: "label-542")
        let view = Referrals.toScheduledFollowUpDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toScheduledFollowUpDraftViews([item, item]).count == 2)
    }
}

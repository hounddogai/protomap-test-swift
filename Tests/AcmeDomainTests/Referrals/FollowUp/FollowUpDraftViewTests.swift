@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpDraft("code-455", label: "label-590")
        let view = Referrals.toFollowUpDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpDraftViews([item, item]).count == 2)
    }
}

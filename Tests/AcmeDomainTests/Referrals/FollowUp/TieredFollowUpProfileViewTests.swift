@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredFollowUpProfile("code-137", label: "label-892")
        let view = Referrals.toTieredFollowUpProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredFollowUpProfileViews([item, item]).count == 2)
    }
}

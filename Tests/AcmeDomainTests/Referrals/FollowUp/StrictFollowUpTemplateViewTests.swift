@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictFollowUpTemplate("code-307", label: "label-15")
        let view = Referrals.toStrictFollowUpTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictFollowUpTemplateViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        let view = Referrals.toSlotTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotTemplateViews([item, item]).count == 2)
    }
}

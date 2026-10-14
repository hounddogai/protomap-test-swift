@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackClosureDraft("code-127", label: "label-649")
        let view = Referrals.toFallbackClosureDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackClosureDraftViews([item, item]).count == 2)
    }
}

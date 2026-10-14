@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualReferralMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        let view = Referrals.toManualReferralMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualReferralMappingViews([item, item]).count == 2)
    }
}

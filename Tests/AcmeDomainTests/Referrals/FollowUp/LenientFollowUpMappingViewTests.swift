@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientFollowUpMapping("code-300", label: "label-930")
        let view = Referrals.toLenientFollowUpMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientFollowUpMappingViews([item, item]).count == 2)
    }
}

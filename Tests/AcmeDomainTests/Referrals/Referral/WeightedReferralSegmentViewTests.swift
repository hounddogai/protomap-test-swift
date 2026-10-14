@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedReferralSegment("code-839", title: "title-688")
        let view = Referrals.toWeightedReferralSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedReferralSegmentViews([item, item]).count == 2)
    }
}

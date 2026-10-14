@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilitySegment("code-523", title: "title-447")
        let view = Referrals.toEligibilitySegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilitySegmentViews([item, item]).count == 2)
    }
}

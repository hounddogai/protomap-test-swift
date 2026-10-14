@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictClosureSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictClosureSegment("code-260", name: "name-429")
        let view = Referrals.toStrictClosureSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictClosureSegmentViews([item, item]).count == 2)
    }
}

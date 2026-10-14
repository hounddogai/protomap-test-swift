@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        let view = Referrals.toClosureEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureEstimateViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedClosureEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedClosureEstimate("code-418", label: "label-754")
        let view = Referrals.toBatchedClosureEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedClosureEstimateViews([item, item]).count == 2)
    }
}

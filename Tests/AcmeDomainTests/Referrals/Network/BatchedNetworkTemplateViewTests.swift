@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedNetworkTemplate("code-277", label: "label-452")
        let view = Referrals.toBatchedNetworkTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedNetworkTemplateViews([item, item]).count == 2)
    }
}

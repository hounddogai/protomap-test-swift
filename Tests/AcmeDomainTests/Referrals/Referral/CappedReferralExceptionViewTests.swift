@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedReferralException("code-362", name: "name-521")
        let view = Referrals.toCappedReferralExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedReferralExceptionViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpException("code-333", label: "label-681")
        let view = Referrals.toFollowUpExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpExceptionViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedClosureRequest("code-557", title: "title-916")
        let view = Referrals.toCappedClosureRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedClosureRequestViews([item, item]).count == 2)
    }
}

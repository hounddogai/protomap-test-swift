@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkWindow("code-304", title: "title-917")
        let view = Referrals.toNetworkWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkWindowViews([item, item]).count == 2)
    }
}

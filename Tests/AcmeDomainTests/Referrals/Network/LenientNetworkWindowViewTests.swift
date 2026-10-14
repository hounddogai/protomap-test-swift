@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        let view = Referrals.toLenientNetworkWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientNetworkWindowViews([item, item]).count == 2)
    }
}

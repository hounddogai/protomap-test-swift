@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        let view = Referrals.toDefaultNetworkWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toDefaultNetworkWindowViews([item, item]).count == 2)
    }
}

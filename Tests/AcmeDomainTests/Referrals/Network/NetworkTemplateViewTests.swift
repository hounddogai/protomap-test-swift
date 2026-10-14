@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkTemplate("code-420", label: "label-562")
        let view = Referrals.toNetworkTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkTemplateViews([item, item]).count == 2)
    }
}

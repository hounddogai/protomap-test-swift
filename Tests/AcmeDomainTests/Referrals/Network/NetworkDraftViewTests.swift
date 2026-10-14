@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkDraft("code-773", name: "name-589")
        let view = Referrals.toNetworkDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkDraftViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        let view = Referrals.toNetworkManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkManifestViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredFollowUpManifest("code-588", label: "label-767")
        let view = Referrals.toTieredFollowUpManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredFollowUpManifestViews([item, item]).count == 2)
    }
}

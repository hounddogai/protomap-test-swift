@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotManifest("code-66", name: "name-630")
        let view = Referrals.toSlotManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotManifestViews([item, item]).count == 2)
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityManifest("code-196", title: "title-516")
        let view = Referrals.toEligibilityManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityManifestViews([item, item]).count == 2)
    }
}

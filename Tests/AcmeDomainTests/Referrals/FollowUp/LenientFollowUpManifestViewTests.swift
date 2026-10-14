@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientFollowUpManifest("code-291", title: "title-556")
        let view = Referrals.toLenientFollowUpManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientFollowUpManifestViews([item, item]).count == 2)
    }
}

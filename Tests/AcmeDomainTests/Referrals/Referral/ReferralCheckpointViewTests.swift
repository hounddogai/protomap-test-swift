@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralCheckpoint("code-875", name: "name-147")
        let view = Referrals.toReferralCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralCheckpointViews([item, item]).count == 2)
    }
}

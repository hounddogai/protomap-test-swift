@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredEligibilityRecord("code-515", title: "title-431")
        let view = Referrals.toTieredEligibilityRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredEligibilityRecordViews([item, item]).count == 2)
    }
}

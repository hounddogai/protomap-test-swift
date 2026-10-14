@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalEligibilityRecord("code-324", title: "title-267")
        let view = Referrals.toSeasonalEligibilityRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalEligibilityRecordViews([item, item]).count == 2)
    }
}

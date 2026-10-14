@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalSlotRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalSlotRecord("code-320", name: "name-706")
        let view = Referrals.toSeasonalSlotRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalSlotRecordViews([item, item]).count == 2)
    }
}

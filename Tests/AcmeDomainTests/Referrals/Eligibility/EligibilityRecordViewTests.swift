@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityRecord("code-558", title: "title-283")
        let view = Referrals.toEligibilityRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityRecordViews([item, item]).count == 2)
    }
}

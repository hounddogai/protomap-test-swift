@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        let view = Referrals.toManualClosureRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualClosureRollupViews([item, item]).count == 2)
    }
}

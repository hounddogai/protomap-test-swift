@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalClosureBundle("code-886", label: "label-846")
        let view = Referrals.toSeasonalClosureBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalClosureBundleViews([item, item]).count == 2)
    }
}

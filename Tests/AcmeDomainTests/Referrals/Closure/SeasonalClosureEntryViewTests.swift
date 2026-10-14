@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalClosureEntry("code-724", title: "title-174")
        let view = Referrals.toSeasonalClosureEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalClosureEntryViews([item, item]).count == 2)
    }
}

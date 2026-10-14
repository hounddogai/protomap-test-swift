@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        let view = CareManagement.toSeasonalCareGapTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalCareGapTierViews([item, item]).count == 2)
    }
}

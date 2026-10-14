@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalCareGapEntry("code-689", title: "title-232")
        let view = CareManagement.toSeasonalCareGapEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalCareGapEntryViews([item, item]).count == 2)
    }
}

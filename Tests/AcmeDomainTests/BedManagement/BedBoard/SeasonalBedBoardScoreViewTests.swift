@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalBedBoardScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        let view = BedManagement.toSeasonalBedBoardScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toSeasonalBedBoardScoreViews([item, item]).count == 2)
    }
}

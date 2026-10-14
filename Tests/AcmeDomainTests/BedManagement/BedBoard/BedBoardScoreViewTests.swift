@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        let view = BedManagement.toBedBoardScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardScoreViews([item, item]).count == 2)
    }
}

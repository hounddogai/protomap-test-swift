@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingBedBoardDraft("code-784", name: "name-398")
        let view = BedManagement.toRollingBedBoardDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingBedBoardDraftViews([item, item]).count == 2)
    }
}

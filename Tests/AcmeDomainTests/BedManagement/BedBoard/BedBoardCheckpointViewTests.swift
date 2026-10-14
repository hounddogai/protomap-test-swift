@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardCheckpoint("code-197", title: "title-827")
        let view = BedManagement.toBedBoardCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardCheckpointViews([item, item]).count == 2)
    }
}

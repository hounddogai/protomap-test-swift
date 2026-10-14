@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        let view = BedManagement.toDefaultBedBoardCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultBedBoardCheckpointViews([item, item]).count == 2)
    }
}

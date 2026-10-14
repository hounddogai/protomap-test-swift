@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryCensusCheckpoint("code-768", title: "title-539")
        let view = BedManagement.toPrimaryCensusCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryCensusCheckpointViews([item, item]).count == 2)
    }
}

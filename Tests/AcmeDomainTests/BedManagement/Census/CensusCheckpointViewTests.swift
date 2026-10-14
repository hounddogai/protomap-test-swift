@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusCheckpoint("code-271", label: "label-859")
        let view = BedManagement.toCensusCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusCheckpointViews([item, item]).count == 2)
    }
}

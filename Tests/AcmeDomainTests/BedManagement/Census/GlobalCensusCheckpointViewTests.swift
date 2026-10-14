@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        let view = BedManagement.toGlobalCensusCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCensusCheckpointViews([item, item]).count == 2)
    }
}

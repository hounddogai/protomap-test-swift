@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationCheckpoint("code-922", label: "label-826")
        let view = BedManagement.toIsolationCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationCheckpointViews([item, item]).count == 2)
    }
}

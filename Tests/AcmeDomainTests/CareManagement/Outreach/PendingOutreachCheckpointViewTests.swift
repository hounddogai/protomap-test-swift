@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingOutreachCheckpoint("code-549", label: "label-460")
        let view = CareManagement.toPendingOutreachCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingOutreachCheckpointViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedOutreachCheckpoint("code-94", name: "name-501")
        let view = CareManagement.toBatchedOutreachCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedOutreachCheckpointViews([item, item]).count == 2)
    }
}

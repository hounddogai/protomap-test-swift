@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledCareGapSnapshot("code-508", title: "title-445")
        let view = CareManagement.toScheduledCareGapSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledCareGapSnapshotViews([item, item]).count == 2)
    }
}

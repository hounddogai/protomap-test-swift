@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapSnapshot("code-369", name: "name-804")
        let view = CareManagement.toCareGapSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapSnapshotViews([item, item]).count == 2)
    }
}

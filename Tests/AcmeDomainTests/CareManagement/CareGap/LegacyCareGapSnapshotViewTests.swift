@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyCareGapSnapshot("code-520", label: "label-791")
        let view = CareManagement.toLegacyCareGapSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyCareGapSnapshotViews([item, item]).count == 2)
    }
}

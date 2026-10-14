@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        let view = CareManagement.toSeasonalCareGapSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalCareGapSnapshotViews([item, item]).count == 2)
    }
}

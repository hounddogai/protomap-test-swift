@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalAssessmentSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalAssessmentSnapshot("code-872", title: "title-979")
        let view = CareManagement.toSeasonalAssessmentSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalAssessmentSnapshotViews([item, item]).count == 2)
    }
}

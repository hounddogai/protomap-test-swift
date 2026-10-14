@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        let view = CareManagement.toTieredAssessmentManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredAssessmentManifestViews([item, item]).count == 2)
    }
}

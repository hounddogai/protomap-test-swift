@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        let view = CareManagement.toFallbackAssessmentManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackAssessmentManifestViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalAssessmentManifest("code-198", label: "label-605")
        let view = CareManagement.toRegionalAssessmentManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalAssessmentManifestViews([item, item]).count == 2)
    }
}

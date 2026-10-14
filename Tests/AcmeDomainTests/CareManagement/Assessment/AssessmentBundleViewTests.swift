@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        let view = CareManagement.toAssessmentBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentBundleViews([item, item]).count == 2)
    }
}

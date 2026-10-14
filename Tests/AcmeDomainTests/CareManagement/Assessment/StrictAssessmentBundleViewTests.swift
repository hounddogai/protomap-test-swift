@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        let view = CareManagement.toStrictAssessmentBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictAssessmentBundleViews([item, item]).count == 2)
    }
}

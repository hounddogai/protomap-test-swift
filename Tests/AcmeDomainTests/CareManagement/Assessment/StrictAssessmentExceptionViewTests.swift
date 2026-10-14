@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        let view = CareManagement.toStrictAssessmentExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictAssessmentExceptionViews([item, item]).count == 2)
    }
}

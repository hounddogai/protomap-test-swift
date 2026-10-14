@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryAssessmentAudit("code-845", name: "name-473")
        let view = CareManagement.toPrimaryAssessmentAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryAssessmentAuditViews([item, item]).count == 2)
    }
}

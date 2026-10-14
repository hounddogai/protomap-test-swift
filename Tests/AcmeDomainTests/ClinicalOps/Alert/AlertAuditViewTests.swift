@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertAudit("code-791", label: "label-362")
        let view = ClinicalOps.toAlertAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertAuditViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLenientOrderSetAudit("code-105", name: "name-4")
        let view = ClinicalOps.toLenientOrderSetAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLenientOrderSetAuditViews([item, item]).count == 2)
    }
}

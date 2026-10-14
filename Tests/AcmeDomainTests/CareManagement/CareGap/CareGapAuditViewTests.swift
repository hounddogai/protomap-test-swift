@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        let view = CareManagement.toCareGapAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapAuditViews([item, item]).count == 2)
    }
}

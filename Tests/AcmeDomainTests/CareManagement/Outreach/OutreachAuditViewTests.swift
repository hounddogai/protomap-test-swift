@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachAudit("code-861", name: "name-43")
        let view = CareManagement.toOutreachAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachAuditViews([item, item]).count == 2)
    }
}

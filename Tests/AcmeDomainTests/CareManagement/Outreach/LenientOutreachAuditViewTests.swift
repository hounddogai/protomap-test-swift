@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        let view = CareManagement.toLenientOutreachAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientOutreachAuditViews([item, item]).count == 2)
    }
}

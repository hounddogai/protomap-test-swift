@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramQuota("code-766", name: "name-849")
        let view = CareManagement.toProgramQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramQuotaViews([item, item]).count == 2)
    }
}

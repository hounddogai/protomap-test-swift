@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalProgramQuota("code-503", title: "title-363")
        let view = CareManagement.toGlobalProgramQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalProgramQuotaViews([item, item]).count == 2)
    }
}

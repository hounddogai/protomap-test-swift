@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramProfile("code-606", label: "label-310")
        let view = CareManagement.toProgramProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramProfileViews([item, item]).count == 2)
    }
}

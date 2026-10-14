@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramGroup("code-665", label: "label-436")
        let view = CareManagement.toProgramGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramGroupViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramTemplate("code-251", name: "name-239")
        let view = CareManagement.toProgramTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramTemplateViews([item, item]).count == 2)
    }
}

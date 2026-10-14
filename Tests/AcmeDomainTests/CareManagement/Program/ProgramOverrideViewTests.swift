@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramOverride("code-82", name: "name-271")
        let view = CareManagement.toProgramOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramOverrideViews([item, item]).count == 2)
    }
}

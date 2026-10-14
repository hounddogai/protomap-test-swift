@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualProgramOverride("code-602", name: "name-260")
        let view = CareManagement.toManualProgramOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualProgramOverrideViews([item, item]).count == 2)
    }
}

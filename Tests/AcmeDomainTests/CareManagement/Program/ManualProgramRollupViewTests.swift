@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualProgramRollup("code-294", name: "name-256")
        let view = CareManagement.toManualProgramRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualProgramRollupViews([item, item]).count == 2)
    }
}

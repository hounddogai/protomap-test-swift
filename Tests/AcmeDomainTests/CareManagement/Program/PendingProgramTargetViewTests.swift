@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingProgramTarget("code-579", name: "name-661")
        let view = CareManagement.toPendingProgramTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingProgramTargetViews([item, item]).count == 2)
    }
}

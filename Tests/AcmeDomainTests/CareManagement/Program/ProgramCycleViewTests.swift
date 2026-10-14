@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramCycle("code-24", title: "title-4")
        let view = CareManagement.toProgramCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramCycleViews([item, item]).count == 2)
    }
}

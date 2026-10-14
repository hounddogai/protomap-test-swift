@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedProgramCycle("code-910", label: "label-110")
        let view = CareManagement.toCappedProgramCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedProgramCycleViews([item, item]).count == 2)
    }
}

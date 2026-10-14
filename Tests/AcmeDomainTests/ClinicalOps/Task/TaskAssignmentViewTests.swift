@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskAssignment("code-636", name: "name-603")
        let view = ClinicalOps.toTaskAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskAssignmentViews([item, item]).count == 2)
    }
}

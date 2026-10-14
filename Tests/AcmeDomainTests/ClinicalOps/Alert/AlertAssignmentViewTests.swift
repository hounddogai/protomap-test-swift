@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertAssignment("code-28", title: "title-782")
        let view = ClinicalOps.toAlertAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertAssignmentViews([item, item]).count == 2)
    }
}

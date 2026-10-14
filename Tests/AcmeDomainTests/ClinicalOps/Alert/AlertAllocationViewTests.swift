@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertAllocation("code-224", label: "label-393")
        let view = ClinicalOps.toAlertAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertAllocationViews([item, item]).count == 2)
    }
}

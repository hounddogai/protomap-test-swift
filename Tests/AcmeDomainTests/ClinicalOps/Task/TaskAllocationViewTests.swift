@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskAllocation("code-789", label: "label-766")
        let view = ClinicalOps.toTaskAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskAllocationViews([item, item]).count == 2)
    }
}

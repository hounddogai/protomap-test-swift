@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingTaskPolicy("code-480", label: "label-874")
        let view = ClinicalOps.toRollingTaskPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingTaskPolicyViews([item, item]).count == 2)
    }
}

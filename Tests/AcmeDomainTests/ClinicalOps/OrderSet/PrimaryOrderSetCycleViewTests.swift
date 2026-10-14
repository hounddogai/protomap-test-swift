@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryOrderSetCycle("code-305", label: "label-356")
        let view = ClinicalOps.toPrimaryOrderSetCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryOrderSetCycleViews([item, item]).count == 2)
    }
}

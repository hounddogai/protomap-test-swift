@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryHandoffCycle("code-108", label: "label-670")
        let view = ClinicalOps.toPrimaryHandoffCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryHandoffCycleViews([item, item]).count == 2)
    }
}

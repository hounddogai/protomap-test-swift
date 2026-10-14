@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredOrderSetCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredOrderSetCycle("code-304", label: "label-66")
        let view = ClinicalOps.toTieredOrderSetCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredOrderSetCycleViews([item, item]).count == 2)
    }
}

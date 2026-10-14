@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredTaskOverride("code-401", label: "label-353")
        let view = ClinicalOps.toTieredTaskOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredTaskOverrideViews([item, item]).count == 2)
    }
}

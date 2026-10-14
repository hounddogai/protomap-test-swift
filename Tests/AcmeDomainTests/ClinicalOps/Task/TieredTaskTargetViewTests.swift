@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredTaskTarget("code-859", name: "name-596")
        let view = ClinicalOps.toTieredTaskTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredTaskTargetViews([item, item]).count == 2)
    }
}

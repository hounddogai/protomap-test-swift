@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictHandoffAdjustment("code-666", name: "name-158")
        let view = ClinicalOps.toStrictHandoffAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictHandoffAdjustmentViews([item, item]).count == 2)
    }
}

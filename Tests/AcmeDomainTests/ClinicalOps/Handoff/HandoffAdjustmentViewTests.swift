@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newHandoffAdjustment("code-512", title: "title-556")
        let view = ClinicalOps.toHandoffAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toHandoffAdjustmentViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedOrderSetRollup("code-100", label: "label-410")
        let view = ClinicalOps.toCappedOrderSetRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedOrderSetRollupViews([item, item]).count == 2)
    }
}

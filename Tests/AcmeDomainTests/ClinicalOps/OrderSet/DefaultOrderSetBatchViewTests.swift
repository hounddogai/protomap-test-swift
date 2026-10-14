@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultOrderSetBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultOrderSetBatch("code-416", label: "label-831")
        let view = ClinicalOps.toDefaultOrderSetBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultOrderSetBatchViews([item, item]).count == 2)
    }
}

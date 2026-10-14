@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultTaskBatch("code-987", title: "title-97")
        let view = ClinicalOps.toDefaultTaskBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultTaskBatchViews([item, item]).count == 2)
    }
}

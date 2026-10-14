@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskBatch("code-546", name: "name-295")
        let view = ClinicalOps.toTaskBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskBatchViews([item, item]).count == 2)
    }
}

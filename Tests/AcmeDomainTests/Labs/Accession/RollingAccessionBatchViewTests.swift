@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        let view = Labs.toRollingAccessionBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingAccessionBatchViews([item, item]).count == 2)
    }
}

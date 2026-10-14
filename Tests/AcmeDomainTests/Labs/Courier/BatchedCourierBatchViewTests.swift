@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        let view = Labs.toBatchedCourierBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedCourierBatchViews([item, item]).count == 2)
    }
}

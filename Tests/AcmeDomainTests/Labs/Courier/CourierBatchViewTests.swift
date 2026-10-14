@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierBatch("code-416", label: "label-450")
        let view = Labs.toCourierBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierBatchViews([item, item]).count == 2)
    }
}

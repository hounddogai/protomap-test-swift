@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackAccessionBatch("code-996", title: "title-191")
        let view = Labs.toFallbackAccessionBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackAccessionBatchViews([item, item]).count == 2)
    }
}

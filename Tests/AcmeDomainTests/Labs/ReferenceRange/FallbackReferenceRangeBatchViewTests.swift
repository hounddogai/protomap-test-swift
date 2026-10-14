@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackReferenceRangeBatch("code-655", title: "title-240")
        let view = Labs.toFallbackReferenceRangeBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackReferenceRangeBatchViews([item, item]).count == 2)
    }
}

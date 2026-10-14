@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingReferenceRangeBatch("code-912", title: "title-701")
        let view = Labs.toPendingReferenceRangeBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingReferenceRangeBatchViews([item, item]).count == 2)
    }
}

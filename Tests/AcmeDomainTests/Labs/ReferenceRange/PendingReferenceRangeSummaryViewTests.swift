@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingReferenceRangeSummary("code-140", title: "title-438")
        let view = Labs.toPendingReferenceRangeSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingReferenceRangeSummaryViews([item, item]).count == 2)
    }
}

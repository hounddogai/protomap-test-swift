@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientReferenceRangeSummary("code-243", label: "label-662")
        let view = Labs.toLenientReferenceRangeSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientReferenceRangeSummaryViews([item, item]).count == 2)
    }
}

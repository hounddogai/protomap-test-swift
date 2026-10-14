@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultSummary("code-534", label: "label-867")
        let view = Labs.toResultSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultSummaryViews([item, item]).count == 2)
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionSummary("code-232", label: "label-859")
        let view = Labs.toAccessionSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionSummaryViews([item, item]).count == 2)
    }
}

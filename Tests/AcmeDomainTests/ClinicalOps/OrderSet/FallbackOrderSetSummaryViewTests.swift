@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackOrderSetSummary("code-231", title: "title-184")
        let view = ClinicalOps.toFallbackOrderSetSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackOrderSetSummaryViews([item, item]).count == 2)
    }
}

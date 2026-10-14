@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackHandoffSummary("code-173", label: "label-70")
        let view = ClinicalOps.toFallbackHandoffSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackHandoffSummaryViews([item, item]).count == 2)
    }
}

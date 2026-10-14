@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        let view = ClinicalOps.toSeasonalRoundingEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalRoundingEstimateViews([item, item]).count == 2)
    }
}

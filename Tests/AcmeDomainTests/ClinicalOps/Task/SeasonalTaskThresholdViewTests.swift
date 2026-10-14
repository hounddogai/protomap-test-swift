@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        let view = ClinicalOps.toSeasonalTaskThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalTaskThresholdViews([item, item]).count == 2)
    }
}

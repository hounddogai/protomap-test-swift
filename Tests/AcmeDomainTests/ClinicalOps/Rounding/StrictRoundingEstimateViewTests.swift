@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictRoundingEstimate("code-603", name: "name-965")
        let view = ClinicalOps.toStrictRoundingEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictRoundingEstimateViews([item, item]).count == 2)
    }
}

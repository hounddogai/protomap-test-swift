@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        let view = ClinicalOps.toPrimaryOrderSetEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryOrderSetEstimateViews([item, item]).count == 2)
    }
}

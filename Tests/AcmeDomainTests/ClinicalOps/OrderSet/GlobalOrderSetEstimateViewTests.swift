@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalOrderSetEstimate("code-6", title: "title-500")
        let view = ClinicalOps.toGlobalOrderSetEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalOrderSetEstimateViews([item, item]).count == 2)
    }
}

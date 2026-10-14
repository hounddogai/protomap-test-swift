@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalCareProtocolEstimate("code-458", label: "label-312")
        let view = ClinicalOps.toRegionalCareProtocolEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalCareProtocolEstimateViews([item, item]).count == 2)
    }
}

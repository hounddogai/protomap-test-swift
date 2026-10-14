@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("code-392", name: "name-581")
        let view = ClinicalOps.toAdaptiveCareProtocolEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveCareProtocolEstimateViews([item, item]).count == 2)
    }
}

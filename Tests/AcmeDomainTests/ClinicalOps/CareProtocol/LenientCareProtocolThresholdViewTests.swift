@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLenientCareProtocolThreshold("code-771", name: "name-236")
        let view = ClinicalOps.toLenientCareProtocolThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLenientCareProtocolThresholdViews([item, item]).count == 2)
    }
}

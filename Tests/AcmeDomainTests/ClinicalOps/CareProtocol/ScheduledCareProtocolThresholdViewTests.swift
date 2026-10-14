@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledCareProtocolThreshold("code-951", name: "name-908")
        let view = ClinicalOps.toScheduledCareProtocolThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledCareProtocolThresholdViews([item, item]).count == 2)
    }
}

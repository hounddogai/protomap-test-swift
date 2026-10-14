@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackCareProtocolThreshold("code-317", title: "title-358")
        let view = ClinicalOps.toFallbackCareProtocolThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackCareProtocolThresholdViews([item, item]).count == 2)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCareProtocolThreshold("code-633", title: "title-816")
        let view = ClinicalOps.toCareProtocolThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCareProtocolThresholdViews([item, item]).count == 2)
    }
}

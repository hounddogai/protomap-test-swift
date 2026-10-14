@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveAlertRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveAlertRequest("code-976", title: "title-972")
        let view = ClinicalOps.toAdaptiveAlertRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveAlertRequestViews([item, item]).count == 2)
    }
}

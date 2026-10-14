@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveHandoffRequest("code-960", label: "label-904")
        let view = ClinicalOps.toAdaptiveHandoffRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveHandoffRequestViews([item, item]).count == 2)
    }
}

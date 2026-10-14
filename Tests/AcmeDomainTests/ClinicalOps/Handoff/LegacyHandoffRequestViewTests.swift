@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyHandoffRequest("code-732", label: "label-236")
        let view = ClinicalOps.toLegacyHandoffRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyHandoffRequestViews([item, item]).count == 2)
    }
}

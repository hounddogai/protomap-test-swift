@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredCareProtocolClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredCareProtocolClaim("code-865", label: "label-345")
        let view = ClinicalOps.toTieredCareProtocolClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredCareProtocolClaimViews([item, item]).count == 2)
    }
}

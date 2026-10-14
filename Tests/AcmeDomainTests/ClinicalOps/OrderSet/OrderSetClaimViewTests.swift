@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newOrderSetClaim("code-688", name: "name-261")
        let view = ClinicalOps.toOrderSetClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toOrderSetClaimViews([item, item]).count == 2)
    }
}

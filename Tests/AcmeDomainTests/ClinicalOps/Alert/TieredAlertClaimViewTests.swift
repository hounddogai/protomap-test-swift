@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredAlertClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredAlertClaim("code-581", title: "title-901")
        let view = ClinicalOps.toTieredAlertClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredAlertClaimViews([item, item]).count == 2)
    }
}

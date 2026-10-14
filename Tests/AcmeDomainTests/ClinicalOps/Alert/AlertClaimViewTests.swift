@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertClaim("code-434", title: "title-146")
        let view = ClinicalOps.toAlertClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertClaimViews([item, item]).count == 2)
    }
}

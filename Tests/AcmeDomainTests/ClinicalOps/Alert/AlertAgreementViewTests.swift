@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertAgreement("code-955", name: "name-671")
        let view = ClinicalOps.toAlertAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertAgreementViews([item, item]).count == 2)
    }
}

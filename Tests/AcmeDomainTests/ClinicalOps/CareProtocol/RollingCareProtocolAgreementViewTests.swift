@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingCareProtocolAgreement("code-932", label: "label-669")
        let view = ClinicalOps.toRollingCareProtocolAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingCareProtocolAgreementViews([item, item]).count == 2)
    }
}

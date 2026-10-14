@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        let view = ClinicalOps.toPrimaryHandoffAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryHandoffAgreementViews([item, item]).count == 2)
    }
}

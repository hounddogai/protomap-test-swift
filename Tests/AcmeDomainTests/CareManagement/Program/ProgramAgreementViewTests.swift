@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramAgreement("code-281", label: "label-169")
        let view = CareManagement.toProgramAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramAgreementViews([item, item]).count == 2)
    }
}

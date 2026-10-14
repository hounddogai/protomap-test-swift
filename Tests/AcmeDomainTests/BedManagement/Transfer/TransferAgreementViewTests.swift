@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferAgreement("code-732", label: "label-639")
        let view = BedManagement.toTransferAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferAgreementViews([item, item]).count == 2)
    }
}

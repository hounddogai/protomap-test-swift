@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingTransferAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingTransferAgreement("code-634", name: "name-826")
        let view = BedManagement.toPendingTransferAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingTransferAgreementViews([item, item]).count == 2)
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedCleaningAgreement("code-120", label: "label-633")
        let view = BedManagement.toCappedCleaningAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedCleaningAgreementViews([item, item]).count == 2)
    }
}

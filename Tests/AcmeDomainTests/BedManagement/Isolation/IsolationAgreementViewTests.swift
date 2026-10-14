@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationAgreement("code-57", name: "name-289")
        let view = BedManagement.toIsolationAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationAgreementViews([item, item]).count == 2)
    }
}

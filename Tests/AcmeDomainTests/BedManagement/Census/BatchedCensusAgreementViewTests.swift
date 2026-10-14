@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCensusAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedCensusAgreement("code-956", name: "name-599")
        let view = BedManagement.toBatchedCensusAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedCensusAgreementViews([item, item]).count == 2)
    }
}

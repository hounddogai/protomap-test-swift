@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingSpecimenAgreement("code-151", label: "label-350")
        let view = Labs.toPendingSpecimenAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingSpecimenAgreementViews([item, item]).count == 2)
    }
}

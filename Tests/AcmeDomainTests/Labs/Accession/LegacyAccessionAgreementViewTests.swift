@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyAccessionAgreement("code-652", label: "label-214")
        let view = Labs.toLegacyAccessionAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyAccessionAgreementViews([item, item]).count == 2)
    }
}

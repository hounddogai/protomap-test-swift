@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        let view = Pharmacy.toDefaultInteractionAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultInteractionAgreementViews([item, item]).count == 2)
    }
}

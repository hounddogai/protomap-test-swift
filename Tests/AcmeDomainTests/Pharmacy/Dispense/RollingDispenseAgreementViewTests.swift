@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingDispenseAgreement("code-876", title: "title-418")
        let view = Pharmacy.toRollingDispenseAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingDispenseAgreementViews([item, item]).count == 2)
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledDispenseAgreement("code-290", title: "title-418")
        let view = Pharmacy.toScheduledDispenseAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledDispenseAgreementViews([item, item]).count == 2)
    }
}

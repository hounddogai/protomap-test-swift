@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispensePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        let view = Pharmacy.toBatchedDispensePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedDispensePolicyViews([item, item]).count == 2)
    }
}

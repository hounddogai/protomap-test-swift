@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedDispenseProfile("code-294", name: "name-351")
        let view = Pharmacy.toBatchedDispenseProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedDispenseProfileViews([item, item]).count == 2)
    }
}

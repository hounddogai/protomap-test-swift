@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        let view = Pharmacy.toBatchedDispenseOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedDispenseOverrideViews([item, item]).count == 2)
    }
}

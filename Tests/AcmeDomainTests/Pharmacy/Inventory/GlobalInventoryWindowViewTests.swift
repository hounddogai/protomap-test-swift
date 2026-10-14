@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        let view = Pharmacy.toGlobalInventoryWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toGlobalInventoryWindowViews([item, item]).count == 2)
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledInventoryWindow("code-144", label: "label-343")
        let view = Pharmacy.toScheduledInventoryWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledInventoryWindowViews([item, item]).count == 2)
    }
}

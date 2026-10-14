@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryWindow("code-519", title: "title-485")
        let view = Pharmacy.toInventoryWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryWindowViews([item, item]).count == 2)
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInventoryRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingInventoryRequest("code-915", title: "title-17")
        let view = Pharmacy.toPendingInventoryRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingInventoryRequestViews([item, item]).count == 2)
    }
}

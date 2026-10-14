@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseSlot("code-112", name: "name-452")
        let view = Pharmacy.toDispenseSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseSlotViews([item, item]).count == 2)
    }
}

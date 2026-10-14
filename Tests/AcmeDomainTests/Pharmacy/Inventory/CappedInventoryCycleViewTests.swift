@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedInventoryCycle("code-491", name: "name-91")
        let view = Pharmacy.toCappedInventoryCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedInventoryCycleViews([item, item]).count == 2)
    }
}

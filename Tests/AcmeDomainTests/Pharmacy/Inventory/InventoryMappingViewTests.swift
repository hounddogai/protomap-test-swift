@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryMapping("code-165", title: "title-429")
        let view = Pharmacy.toInventoryMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryMappingViews([item, item]).count == 2)
    }
}

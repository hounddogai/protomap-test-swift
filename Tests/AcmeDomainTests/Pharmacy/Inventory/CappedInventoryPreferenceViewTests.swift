@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedInventoryPreference("code-873", name: "name-856")
        let view = Pharmacy.toCappedInventoryPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedInventoryPreferenceViews([item, item]).count == 2)
    }
}

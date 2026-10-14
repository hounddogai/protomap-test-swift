@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryEntry("code-220", label: "label-665")
        let view = Pharmacy.toInventoryEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryEntryViews([item, item]).count == 2)
    }
}

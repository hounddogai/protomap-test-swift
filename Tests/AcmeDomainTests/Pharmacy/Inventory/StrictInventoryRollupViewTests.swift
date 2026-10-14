@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictInventoryRollup("code-645", title: "title-748")
        let view = Pharmacy.toStrictInventoryRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictInventoryRollupViews([item, item]).count == 2)
    }
}

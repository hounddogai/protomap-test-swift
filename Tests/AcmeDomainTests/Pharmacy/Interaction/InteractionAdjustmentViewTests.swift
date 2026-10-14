@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionAdjustment("code-971", name: "name-879")
        let view = Pharmacy.toInteractionAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionAdjustmentViews([item, item]).count == 2)
    }
}

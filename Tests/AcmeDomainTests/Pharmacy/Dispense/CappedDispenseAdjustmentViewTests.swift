@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedDispenseAdjustment("code-219", title: "title-964")
        let view = Pharmacy.toCappedDispenseAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedDispenseAdjustmentViews([item, item]).count == 2)
    }
}

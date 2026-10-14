@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseAdjustment("code-434", name: "name-328")
        let view = Pharmacy.toDispenseAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseAdjustmentViews([item, item]).count == 2)
    }
}

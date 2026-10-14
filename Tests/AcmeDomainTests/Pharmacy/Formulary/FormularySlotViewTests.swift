@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularySlot("code-816", title: "title-381")
        let view = Pharmacy.toFormularySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularySlotViews([item, item]).count == 2)
    }
}

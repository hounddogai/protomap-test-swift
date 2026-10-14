@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyRecallSlot("code-187", name: "name-147")
        let view = Pharmacy.toLegacyRecallSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyRecallSlotViews([item, item]).count == 2)
    }
}

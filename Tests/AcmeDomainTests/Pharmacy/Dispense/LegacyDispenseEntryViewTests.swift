@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyDispenseEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyDispenseEntry("code-401", label: "label-68")
        let view = Pharmacy.toLegacyDispenseEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyDispenseEntryViews([item, item]).count == 2)
    }
}

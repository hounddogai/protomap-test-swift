@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseEntry("code-719", title: "title-668")
        let view = Pharmacy.toDispenseEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseEntryViews([item, item]).count == 2)
    }
}

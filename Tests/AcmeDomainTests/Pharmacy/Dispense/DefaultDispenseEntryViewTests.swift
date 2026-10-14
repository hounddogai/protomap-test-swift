@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultDispenseEntry("code-469", name: "name-796")
        let view = Pharmacy.toDefaultDispenseEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultDispenseEntryViews([item, item]).count == 2)
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedFormularyEntry("code-329", title: "title-224")
        let view = Pharmacy.toWeightedFormularyEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedFormularyEntryViews([item, item]).count == 2)
    }
}

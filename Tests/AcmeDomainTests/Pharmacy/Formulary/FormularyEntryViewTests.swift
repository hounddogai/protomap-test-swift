@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyEntry("code-791", label: "label-255")
        let view = Pharmacy.toFormularyEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyEntryViews([item, item]).count == 2)
    }
}

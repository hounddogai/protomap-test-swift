@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalInteractionWindow("code-907", title: "title-157")
        let view = Pharmacy.toRegionalInteractionWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalInteractionWindowViews([item, item]).count == 2)
    }
}

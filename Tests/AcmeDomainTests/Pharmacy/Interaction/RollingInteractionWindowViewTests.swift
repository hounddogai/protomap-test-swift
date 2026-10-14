@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingInteractionWindow("code-629", title: "title-185")
        let view = Pharmacy.toRollingInteractionWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingInteractionWindowViews([item, item]).count == 2)
    }
}

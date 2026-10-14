@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionProfile("code-920", name: "name-587")
        let view = Pharmacy.toInteractionProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionProfileViews([item, item]).count == 2)
    }
}

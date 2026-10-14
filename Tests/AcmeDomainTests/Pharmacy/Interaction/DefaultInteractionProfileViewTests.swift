@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultInteractionProfile("code-210", name: "name-598")
        let view = Pharmacy.toDefaultInteractionProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultInteractionProfileViews([item, item]).count == 2)
    }
}

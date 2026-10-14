@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionGroup("code-116", label: "label-988")
        let view = Pharmacy.toInteractionGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionGroupViews([item, item]).count == 2)
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyGroup("code-283", name: "name-803")
        let view = Pharmacy.toFormularyGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyGroupViews([item, item]).count == 2)
    }
}

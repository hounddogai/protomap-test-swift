@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseGroup("code-856", name: "name-821")
        let view = Pharmacy.toDispenseGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseGroupViews([item, item]).count == 2)
    }
}

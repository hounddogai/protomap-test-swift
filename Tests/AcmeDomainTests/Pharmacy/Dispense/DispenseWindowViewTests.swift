@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseWindow("code-116", name: "name-614")
        let view = Pharmacy.toDispenseWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseWindowViews([item, item]).count == 2)
    }
}

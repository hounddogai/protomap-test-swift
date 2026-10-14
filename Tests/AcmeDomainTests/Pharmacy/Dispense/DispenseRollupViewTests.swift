@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseRollup("code-409", name: "name-844")
        let view = Pharmacy.toDispenseRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseRollupViews([item, item]).count == 2)
    }
}

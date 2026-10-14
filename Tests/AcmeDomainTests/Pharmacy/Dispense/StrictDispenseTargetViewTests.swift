@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictDispenseTarget("code-608", label: "label-588")
        let view = Pharmacy.toStrictDispenseTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictDispenseTargetViews([item, item]).count == 2)
    }
}

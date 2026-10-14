@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictFormularyAllocation("code-104", label: "label-484")
        let view = Pharmacy.toStrictFormularyAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictFormularyAllocationViews([item, item]).count == 2)
    }
}

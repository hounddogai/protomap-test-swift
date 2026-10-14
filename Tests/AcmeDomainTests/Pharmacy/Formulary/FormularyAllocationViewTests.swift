@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyAllocation("code-829", label: "label-390")
        let view = Pharmacy.toFormularyAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyAllocationViews([item, item]).count == 2)
    }
}

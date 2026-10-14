@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionAllocation("code-442", name: "name-172")
        let view = Pharmacy.toInteractionAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionAllocationViews([item, item]).count == 2)
    }
}

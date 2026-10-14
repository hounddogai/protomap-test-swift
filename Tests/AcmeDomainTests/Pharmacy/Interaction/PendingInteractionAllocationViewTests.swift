@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        let view = Pharmacy.toPendingInteractionAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingInteractionAllocationViews([item, item]).count == 2)
    }
}

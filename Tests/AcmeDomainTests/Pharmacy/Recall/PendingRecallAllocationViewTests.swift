@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingRecallAllocation("code-741", name: "name-308")
        let view = Pharmacy.toPendingRecallAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingRecallAllocationViews([item, item]).count == 2)
    }
}

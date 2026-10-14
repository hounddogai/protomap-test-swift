@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingSubstitutionAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        let view = Pharmacy.toPendingSubstitutionAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingSubstitutionAllocationViews([item, item]).count == 2)
    }
}

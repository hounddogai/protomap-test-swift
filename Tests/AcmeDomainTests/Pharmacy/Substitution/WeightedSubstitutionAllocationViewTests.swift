@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        let view = Pharmacy.toWeightedSubstitutionAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedSubstitutionAllocationViews([item, item]).count == 2)
    }
}

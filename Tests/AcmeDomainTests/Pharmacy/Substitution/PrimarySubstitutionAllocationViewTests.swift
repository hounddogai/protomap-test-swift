@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimarySubstitutionAllocation("code-980", name: "name-294")
        let view = Pharmacy.toPrimarySubstitutionAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimarySubstitutionAllocationViews([item, item]).count == 2)
    }
}

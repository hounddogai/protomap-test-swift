@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedSubstitutionBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        let view = Pharmacy.toCappedSubstitutionBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedSubstitutionBaselineViews([item, item]).count == 2)
    }
}

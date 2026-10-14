@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSubstitutionGroup("code-803", name: "name-143")
        let view = Pharmacy.toSubstitutionGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSubstitutionGroupViews([item, item]).count == 2)
    }
}

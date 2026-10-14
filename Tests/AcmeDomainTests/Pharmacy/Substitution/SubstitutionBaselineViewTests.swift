@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSubstitutionBaseline("code-688", title: "title-927")
        let view = Pharmacy.toSubstitutionBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSubstitutionBaselineViews([item, item]).count == 2)
    }
}

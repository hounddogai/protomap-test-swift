@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedSubstitutionPolicy("code-38", name: "name-215")
        let view = Pharmacy.toBatchedSubstitutionPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedSubstitutionPolicyViews([item, item]).count == 2)
    }
}

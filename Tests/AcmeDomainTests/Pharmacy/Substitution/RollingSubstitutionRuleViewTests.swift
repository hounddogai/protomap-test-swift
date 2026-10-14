@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingSubstitutionRule("code-144", name: "name-1")
        let view = Pharmacy.toRollingSubstitutionRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingSubstitutionRuleViews([item, item]).count == 2)
    }
}

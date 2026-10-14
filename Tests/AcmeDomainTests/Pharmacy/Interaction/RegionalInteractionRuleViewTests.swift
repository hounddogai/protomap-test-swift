@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalInteractionRule("code-85", name: "name-191")
        let view = Pharmacy.toRegionalInteractionRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalInteractionRuleViews([item, item]).count == 2)
    }
}

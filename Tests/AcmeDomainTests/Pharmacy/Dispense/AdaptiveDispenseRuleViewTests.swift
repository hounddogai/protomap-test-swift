@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveDispenseRule("code-736", title: "title-584")
        let view = Pharmacy.toAdaptiveDispenseRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveDispenseRuleViews([item, item]).count == 2)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalDisclosureRule("code-797", label: "label-514")
        let view = Consent.toGlobalDisclosureRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalDisclosureRuleViews([item, item]).count == 2)
    }
}

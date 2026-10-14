@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackDisclosureAdjustment("code-586", name: "name-417")
        let view = Consent.toFallbackDisclosureAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackDisclosureAdjustmentViews([item, item]).count == 2)
    }
}

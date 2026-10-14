@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureAdjustment("code-950", label: "label-110")
        let view = Consent.toDisclosureAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureAdjustmentViews([item, item]).count == 2)
    }
}

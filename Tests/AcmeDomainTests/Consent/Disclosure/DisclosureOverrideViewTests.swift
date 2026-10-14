@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureOverride("code-660", label: "label-345")
        let view = Consent.toDisclosureOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureOverrideViews([item, item]).count == 2)
    }
}

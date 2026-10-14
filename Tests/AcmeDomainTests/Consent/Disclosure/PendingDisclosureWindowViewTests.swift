@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        let view = Consent.toPendingDisclosureWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingDisclosureWindowViews([item, item]).count == 2)
    }
}

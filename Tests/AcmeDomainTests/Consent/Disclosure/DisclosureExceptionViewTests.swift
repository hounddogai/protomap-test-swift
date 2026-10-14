@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureException("code-542", name: "name-246")
        let view = Consent.toDisclosureExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureExceptionViews([item, item]).count == 2)
    }
}

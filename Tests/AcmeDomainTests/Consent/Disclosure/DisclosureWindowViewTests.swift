@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureWindow("code-739", name: "name-678")
        let view = Consent.toDisclosureWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureWindowViews([item, item]).count == 2)
    }
}

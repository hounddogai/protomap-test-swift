@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureProfile("code-831", name: "name-811")
        let view = Consent.toDisclosureProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureProfileViews([item, item]).count == 2)
    }
}

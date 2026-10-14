@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationWindow("code-790", title: "title-997")
        let view = Consent.toRevocationWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationWindowViews([item, item]).count == 2)
    }
}

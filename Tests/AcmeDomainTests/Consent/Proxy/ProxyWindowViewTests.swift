@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        let view = Consent.toProxyWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyWindowViews([item, item]).count == 2)
    }
}

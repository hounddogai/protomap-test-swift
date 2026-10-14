@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyOverride("code-282", name: "name-145")
        let view = Consent.toProxyOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyOverrideViews([item, item]).count == 2)
    }
}

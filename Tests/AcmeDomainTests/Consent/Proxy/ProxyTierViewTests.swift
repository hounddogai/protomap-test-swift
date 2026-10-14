@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyTier("code-981", name: "name-262")
        let view = Consent.toProxyTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyTierViews([item, item]).count == 2)
    }
}

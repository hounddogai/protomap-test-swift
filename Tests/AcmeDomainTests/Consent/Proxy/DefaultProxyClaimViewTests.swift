@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        let view = Consent.toDefaultProxyClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultProxyClaimViews([item, item]).count == 2)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyProfile("code-28", title: "title-168")
        let view = Consent.toProxyProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyProfileViews([item, item]).count == 2)
    }
}

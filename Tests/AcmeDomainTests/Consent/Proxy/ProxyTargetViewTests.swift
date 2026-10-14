@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyTarget("code-477", name: "name-474")
        let view = Consent.toProxyTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyTargetViews([item, item]).count == 2)
    }
}

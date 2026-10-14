@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        let view = Consent.toDefaultProxyScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultProxyScoreViews([item, item]).count == 2)
    }
}

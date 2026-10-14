@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictProxyTarget("code-647", label: "label-82")
        let view = Consent.toStrictProxyTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictProxyTargetViews([item, item]).count == 2)
    }
}

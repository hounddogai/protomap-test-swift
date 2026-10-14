@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedProxyTarget("code-142", name: "name-196")
        let view = Consent.toCappedProxyTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedProxyTargetViews([item, item]).count == 2)
    }
}

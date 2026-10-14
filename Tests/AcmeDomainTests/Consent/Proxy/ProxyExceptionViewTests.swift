@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyException("code-305", label: "label-368")
        let view = Consent.toProxyExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyExceptionViews([item, item]).count == 2)
    }
}

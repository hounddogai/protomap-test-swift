@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedProxyException("code-51", title: "title-850")
        let view = Consent.toBatchedProxyExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedProxyExceptionViews([item, item]).count == 2)
    }
}

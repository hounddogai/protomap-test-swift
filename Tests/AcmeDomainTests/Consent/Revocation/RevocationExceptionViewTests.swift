@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationException("code-874", name: "name-916")
        let view = Consent.toRevocationExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationExceptionViews([item, item]).count == 2)
    }
}

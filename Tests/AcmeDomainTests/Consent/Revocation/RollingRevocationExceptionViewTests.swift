@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingRevocationException("code-368", label: "label-734")
        let view = Consent.toRollingRevocationExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingRevocationExceptionViews([item, item]).count == 2)
    }
}

@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveRevocationException("code-979", name: "name-115")
        let view = Consent.toAdaptiveRevocationExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveRevocationExceptionViews([item, item]).count == 2)
    }
}

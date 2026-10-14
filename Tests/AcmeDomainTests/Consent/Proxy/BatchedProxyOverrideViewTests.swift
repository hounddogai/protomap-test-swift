@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedProxyOverride("code-993", label: "label-67")
        let view = Consent.toBatchedProxyOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedProxyOverrideViews([item, item]).count == 2)
    }
}

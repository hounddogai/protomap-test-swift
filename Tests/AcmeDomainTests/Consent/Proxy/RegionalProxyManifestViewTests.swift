@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalProxyManifest("code-2", label: "label-791")
        let view = Consent.toRegionalProxyManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalProxyManifestViews([item, item]).count == 2)
    }
}

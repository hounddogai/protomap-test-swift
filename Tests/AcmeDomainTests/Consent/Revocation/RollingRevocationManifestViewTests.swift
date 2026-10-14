@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        let view = Consent.toRollingRevocationManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingRevocationManifestViews([item, item]).count == 2)
    }
}

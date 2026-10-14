@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        let view = Consent.toWitnessManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessManifestViews([item, item]).count == 2)
    }
}

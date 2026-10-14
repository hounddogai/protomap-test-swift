@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormSnapshot("code-150", label: "label-455")
        let view = Consent.toConsentFormSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormSnapshotViews([item, item]).count == 2)
    }
}

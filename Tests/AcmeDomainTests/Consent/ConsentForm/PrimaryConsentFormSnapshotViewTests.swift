@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        let view = Consent.toPrimaryConsentFormSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryConsentFormSnapshotViews([item, item]).count == 2)
    }
}

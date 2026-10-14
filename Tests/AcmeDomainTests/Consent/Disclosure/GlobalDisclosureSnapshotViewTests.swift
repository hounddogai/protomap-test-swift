@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalDisclosureSnapshot("code-218", label: "label-216")
        let view = Consent.toGlobalDisclosureSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalDisclosureSnapshotViews([item, item]).count == 2)
    }
}

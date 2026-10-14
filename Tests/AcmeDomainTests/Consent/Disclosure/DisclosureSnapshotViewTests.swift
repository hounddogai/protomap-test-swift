@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureSnapshot("code-940", title: "title-514")
        let view = Consent.toDisclosureSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureSnapshotViews([item, item]).count == 2)
    }
}

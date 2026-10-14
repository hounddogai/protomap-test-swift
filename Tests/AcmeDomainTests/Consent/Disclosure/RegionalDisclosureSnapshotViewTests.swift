@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalDisclosureSnapshot("code-613", title: "title-429")
        let view = Consent.toRegionalDisclosureSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalDisclosureSnapshotViews([item, item]).count == 2)
    }
}

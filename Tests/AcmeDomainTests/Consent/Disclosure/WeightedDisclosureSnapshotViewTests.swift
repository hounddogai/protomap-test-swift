@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedDisclosureSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        let view = Consent.toWeightedDisclosureSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWeightedDisclosureSnapshotViews([item, item]).count == 2)
    }
}

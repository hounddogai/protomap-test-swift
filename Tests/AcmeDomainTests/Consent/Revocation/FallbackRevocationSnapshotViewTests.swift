@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackRevocationSnapshot("code-174", title: "title-379")
        let view = Consent.toFallbackRevocationSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackRevocationSnapshotViews([item, item]).count == 2)
    }
}

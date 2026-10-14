@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureCheckpoint("code-799", title: "title-782")
        let view = Consent.toDisclosureCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureCheckpointViews([item, item]).count == 2)
    }
}

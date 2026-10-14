@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessCheckpoint("code-552", title: "title-691")
        let view = Consent.toWitnessCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessCheckpointViews([item, item]).count == 2)
    }
}

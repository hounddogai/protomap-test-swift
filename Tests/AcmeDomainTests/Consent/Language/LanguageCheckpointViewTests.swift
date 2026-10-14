@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        let view = Consent.toLanguageCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageCheckpointViews([item, item]).count == 2)
    }
}

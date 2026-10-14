@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        let view = Consent.toSeasonalLanguageCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalLanguageCheckpointViews([item, item]).count == 2)
    }
}

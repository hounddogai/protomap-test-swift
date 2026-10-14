@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientLanguageCheckpoint("code-99", title: "title-455")
        let view = Consent.toLenientLanguageCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientLanguageCheckpointViews([item, item]).count == 2)
    }
}

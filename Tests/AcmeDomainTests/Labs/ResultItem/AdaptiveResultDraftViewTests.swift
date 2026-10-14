@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveResultDraft("code-913", name: "name-856")
        let view = Labs.toAdaptiveResultDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveResultDraftViews([item, item]).count == 2)
    }
}

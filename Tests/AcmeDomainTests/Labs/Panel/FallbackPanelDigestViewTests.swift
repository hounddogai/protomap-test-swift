@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackPanelDigest("code-629", title: "title-634")
        let view = Labs.toFallbackPanelDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackPanelDigestViews([item, item]).count == 2)
    }
}

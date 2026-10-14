@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        let view = Labs.toAdaptivePanelDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptivePanelDigestViews([item, item]).count == 2)
    }
}

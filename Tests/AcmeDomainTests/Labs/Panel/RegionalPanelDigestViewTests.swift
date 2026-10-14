@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalPanelDigest("code-148", title: "title-871")
        let view = Labs.toRegionalPanelDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalPanelDigestViews([item, item]).count == 2)
    }
}

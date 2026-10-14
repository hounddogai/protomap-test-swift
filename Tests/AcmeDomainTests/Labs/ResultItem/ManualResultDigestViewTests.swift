@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newManualResultDigest("code-885", title: "title-570")
        let view = Labs.toManualResultDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toManualResultDigestViews([item, item]).count == 2)
    }
}

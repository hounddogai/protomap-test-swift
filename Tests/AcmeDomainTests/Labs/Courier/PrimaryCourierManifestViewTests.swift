@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        let view = Labs.toPrimaryCourierManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryCourierManifestViews([item, item]).count == 2)
    }
}

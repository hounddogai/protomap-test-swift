@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelManifest("code-151", label: "label-819")
        let view = Labs.toPanelManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelManifestViews([item, item]).count == 2)
    }
}

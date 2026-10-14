@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultManifest("code-936", label: "label-379")
        let view = Labs.toResultManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultManifestViews([item, item]).count == 2)
    }
}

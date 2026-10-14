@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenManifest("code-290", label: "label-273")
        let view = Labs.toSpecimenManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenManifestViews([item, item]).count == 2)
    }
}

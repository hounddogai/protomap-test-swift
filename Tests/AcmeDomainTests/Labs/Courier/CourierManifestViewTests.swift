@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        let view = Labs.toCourierManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierManifestViews([item, item]).count == 2)
    }
}

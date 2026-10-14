@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeManifest("code-512", name: "name-245")
        let view = Labs.toReferenceRangeManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeManifestViews([item, item]).count == 2)
    }
}

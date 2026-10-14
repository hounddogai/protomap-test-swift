@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultManifestTests {
    @Test func startsInCreated() throws {
        let item = Labs.newResultManifest("code-936", label: "label-379")
        #expect(item.status == Labs.ResultManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newResultManifest("code-936", label: "label-379")
        try item.moveTo(Labs.ResultManifestStatus.validated)
        #expect(item.status == Labs.ResultManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newResultManifest("code-936", label: "label-379")
        item.status = Labs.ResultManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultManifestStatus.created) }
    }
}

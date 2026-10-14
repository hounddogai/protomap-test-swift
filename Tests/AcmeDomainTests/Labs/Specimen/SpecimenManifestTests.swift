@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenManifestTests {
    @Test func startsInCreated() throws {
        let item = Labs.newSpecimenManifest("code-290", label: "label-273")
        #expect(item.status == Labs.SpecimenManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newSpecimenManifest("code-290", label: "label-273")
        try item.moveTo(Labs.SpecimenManifestStatus.validated)
        #expect(item.status == Labs.SpecimenManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newSpecimenManifest("code-290", label: "label-273")
        item.status = Labs.SpecimenManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenManifestStatus.created) }
    }
}

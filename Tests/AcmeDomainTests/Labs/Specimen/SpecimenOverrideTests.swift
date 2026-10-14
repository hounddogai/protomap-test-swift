@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSpecimenOverride("code-75", title: "title-537")
        #expect(item.status == Labs.SpecimenOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newSpecimenOverride("code-75", title: "title-537")
        try item.moveTo(Labs.SpecimenOverrideStatus.inProgress)
        #expect(item.status == Labs.SpecimenOverrideStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSpecimenOverride("code-75", title: "title-537")
        item.status = Labs.SpecimenOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenOverrideStatus.planned) }
    }
}

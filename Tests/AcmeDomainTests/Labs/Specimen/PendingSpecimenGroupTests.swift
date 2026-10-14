@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenGroupTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPendingSpecimenGroup("code-764", label: "label-694")
        #expect(item.status == Labs.PendingSpecimenGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newPendingSpecimenGroup("code-764", label: "label-694")
        try item.moveTo(Labs.PendingSpecimenGroupStatus.scheduled)
        #expect(item.status == Labs.PendingSpecimenGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPendingSpecimenGroup("code-764", label: "label-694")
        item.status = Labs.PendingSpecimenGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingSpecimenGroupStatus.planned) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenAllocationTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenAllocation("code-9", title: "title-131")
        #expect(item.status == Labs.SpecimenAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newSpecimenAllocation("code-9", title: "title-131")
        try item.moveTo(Labs.SpecimenAllocationStatus.queued)
        #expect(item.status == Labs.SpecimenAllocationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenAllocation("code-9", title: "title-131")
        item.status = Labs.SpecimenAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenAllocationStatus.new) }
    }
}

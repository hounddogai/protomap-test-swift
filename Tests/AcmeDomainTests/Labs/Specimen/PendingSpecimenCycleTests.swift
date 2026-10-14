@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenCycleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPendingSpecimenCycle("code-604", label: "label-545")
        #expect(item.status == Labs.PendingSpecimenCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newPendingSpecimenCycle("code-604", label: "label-545")
        try item.moveTo(Labs.PendingSpecimenCycleStatus.expired)
        #expect(item.status == Labs.PendingSpecimenCycleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPendingSpecimenCycle("code-604", label: "label-545")
        item.status = Labs.PendingSpecimenCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingSpecimenCycleStatus.requested) }
    }
}

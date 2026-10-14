@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeAllocationTests {
    @Test func startsInRequested() throws {
        let item = Labs.newCappedReferenceRangeAllocation("code-685", name: "name-519")
        #expect(item.status == Labs.CappedReferenceRangeAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newCappedReferenceRangeAllocation("code-685", name: "name-519")
        try item.moveTo(Labs.CappedReferenceRangeAllocationStatus.revoked)
        #expect(item.status == Labs.CappedReferenceRangeAllocationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newCappedReferenceRangeAllocation("code-685", name: "name-519")
        item.status = Labs.CappedReferenceRangeAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedReferenceRangeAllocationStatus.requested) }
    }
}

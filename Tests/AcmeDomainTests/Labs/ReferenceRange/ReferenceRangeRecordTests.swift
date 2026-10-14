@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRecordTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeRecord("code-804", name: "name-164")
        #expect(item.status == Labs.ReferenceRangeRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newReferenceRangeRecord("code-804", name: "name-164")
        try item.moveTo(Labs.ReferenceRangeRecordStatus.stopped)
        #expect(item.status == Labs.ReferenceRangeRecordStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeRecord("code-804", name: "name-164")
        item.status = Labs.ReferenceRangeRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeRecordStatus.idle) }
    }
}

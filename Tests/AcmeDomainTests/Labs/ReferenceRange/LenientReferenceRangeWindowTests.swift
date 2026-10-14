@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeWindowTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newLenientReferenceRangeWindow("code-174", name: "name-629")
        #expect(item.status == Labs.LenientReferenceRangeWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newLenientReferenceRangeWindow("code-174", name: "name-629")
        try item.moveTo(Labs.LenientReferenceRangeWindowStatus.scheduled)
        #expect(item.status == Labs.LenientReferenceRangeWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newLenientReferenceRangeWindow("code-174", name: "name-629")
        item.status = Labs.LenientReferenceRangeWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeWindowStatus.planned) }
    }
}

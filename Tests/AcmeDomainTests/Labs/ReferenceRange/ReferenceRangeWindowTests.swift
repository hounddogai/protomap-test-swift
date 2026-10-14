@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeWindowTests {
    @Test func startsInRequested() throws {
        let item = Labs.newReferenceRangeWindow("code-34", title: "title-617")
        #expect(item.status == Labs.ReferenceRangeWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newReferenceRangeWindow("code-34", title: "title-617")
        try item.moveTo(Labs.ReferenceRangeWindowStatus.expired)
        #expect(item.status == Labs.ReferenceRangeWindowStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newReferenceRangeWindow("code-34", title: "title-617")
        item.status = Labs.ReferenceRangeWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeWindowStatus.requested) }
    }
}

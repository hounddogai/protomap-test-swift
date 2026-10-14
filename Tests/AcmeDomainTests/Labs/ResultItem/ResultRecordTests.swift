@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRecordTests {
    @Test func startsInDraft() throws {
        let item = Labs.newResultRecord("code-777", label: "label-506")
        #expect(item.status == Labs.ResultRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newResultRecord("code-777", label: "label-506")
        try item.moveTo(Labs.ResultRecordStatus.suspended)
        #expect(item.status == Labs.ResultRecordStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newResultRecord("code-777", label: "label-506")
        item.status = Labs.ResultRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultRecordStatus.draft) }
    }
}

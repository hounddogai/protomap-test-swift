@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionRecordTests {
    @Test func startsInProposed() throws {
        let item = Labs.newRollingAccessionRecord("code-437", name: "name-406")
        #expect(item.status == Labs.RollingAccessionRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newRollingAccessionRecord("code-437", name: "name-406")
        try item.moveTo(Labs.RollingAccessionRecordStatus.rejected)
        #expect(item.status == Labs.RollingAccessionRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newRollingAccessionRecord("code-437", name: "name-406")
        item.status = Labs.RollingAccessionRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingAccessionRecordStatus.proposed) }
    }
}

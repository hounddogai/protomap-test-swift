@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRecordTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionRecord("code-433", name: "name-70")
        #expect(item.status == Labs.AccessionRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newAccessionRecord("code-433", name: "name-70")
        try item.moveTo(Labs.AccessionRecordStatus.draining)
        #expect(item.status == Labs.AccessionRecordStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionRecord("code-433", name: "name-70")
        item.status = Labs.AccessionRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionRecordStatus.idle) }
    }
}

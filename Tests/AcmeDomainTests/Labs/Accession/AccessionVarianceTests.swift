@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAccessionVariance("code-249", name: "name-850")
        #expect(item.status == Labs.AccessionVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newAccessionVariance("code-249", name: "name-850")
        try item.moveTo(Labs.AccessionVarianceStatus.inProgress)
        #expect(item.status == Labs.AccessionVarianceStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAccessionVariance("code-249", name: "name-850")
        item.status = Labs.AccessionVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionVarianceStatus.planned) }
    }
}

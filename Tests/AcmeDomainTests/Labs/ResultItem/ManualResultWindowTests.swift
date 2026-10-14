@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultWindowTests {
    @Test func startsInOpen() throws {
        let item = Labs.newManualResultWindow("code-216", name: "name-440")
        #expect(item.status == Labs.ManualResultWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newManualResultWindow("code-216", name: "name-440")
        try item.moveTo(Labs.ManualResultWindowStatus.resolved)
        #expect(item.status == Labs.ManualResultWindowStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newManualResultWindow("code-216", name: "name-440")
        item.status = Labs.ManualResultWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualResultWindowStatus.`open`) }
    }
}

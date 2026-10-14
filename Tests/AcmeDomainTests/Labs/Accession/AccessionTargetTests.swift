@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionTargetTests {
    @Test func startsInNew() throws {
        let item = Labs.newAccessionTarget("code-996", name: "name-854")
        #expect(item.status == Labs.AccessionTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newAccessionTarget("code-996", name: "name-854")
        try item.moveTo(Labs.AccessionTargetStatus.failed)
        #expect(item.status == Labs.AccessionTargetStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAccessionTarget("code-996", name: "name-854")
        item.status = Labs.AccessionTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionTargetStatus.new) }
    }
}

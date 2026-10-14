@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingReferenceRangeRollupTests {
    @Test func startsInNew() throws {
        let item = Labs.newRollingReferenceRangeRollup("code-385", label: "label-981")
        #expect(item.status == Labs.RollingReferenceRangeRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newRollingReferenceRangeRollup("code-385", label: "label-981")
        try item.moveTo(Labs.RollingReferenceRangeRollupStatus.running)
        #expect(item.status == Labs.RollingReferenceRangeRollupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newRollingReferenceRangeRollup("code-385", label: "label-981")
        item.status = Labs.RollingReferenceRangeRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingReferenceRangeRollupStatus.new) }
    }
}

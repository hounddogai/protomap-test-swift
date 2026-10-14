@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierTierTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        #expect(item.status == Labs.GlobalCourierTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        try item.moveTo(Labs.GlobalCourierTierStatus.scheduled)
        #expect(item.status == Labs.GlobalCourierTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        item.status = Labs.GlobalCourierTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalCourierTierStatus.planned) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenRuleTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalSpecimenRule("code-950", title: "title-597")
        #expect(item.status == Labs.GlobalSpecimenRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newGlobalSpecimenRule("code-950", title: "title-597")
        try item.moveTo(Labs.GlobalSpecimenRuleStatus.running)
        #expect(item.status == Labs.GlobalSpecimenRuleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalSpecimenRule("code-950", title: "title-597")
        item.status = Labs.GlobalSpecimenRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalSpecimenRuleStatus.new) }
    }
}

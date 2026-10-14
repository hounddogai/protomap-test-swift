@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRuleTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenRule("code-676", title: "title-472")
        #expect(item.status == Labs.SpecimenRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSpecimenRule("code-676", title: "title-472")
        try item.moveTo(Labs.SpecimenRuleStatus.running)
        #expect(item.status == Labs.SpecimenRuleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenRule("code-676", title: "title-472")
        item.status = Labs.SpecimenRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenRuleStatus.new) }
    }
}

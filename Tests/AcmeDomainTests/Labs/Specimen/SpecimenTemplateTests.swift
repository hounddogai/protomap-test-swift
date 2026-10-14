@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenTemplateTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenTemplate("code-476", title: "title-316")
        #expect(item.status == Labs.SpecimenTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newSpecimenTemplate("code-476", title: "title-316")
        try item.moveTo(Labs.SpecimenTemplateStatus.queued)
        #expect(item.status == Labs.SpecimenTemplateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenTemplate("code-476", title: "title-316")
        item.status = Labs.SpecimenTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenTemplateStatus.new) }
    }
}

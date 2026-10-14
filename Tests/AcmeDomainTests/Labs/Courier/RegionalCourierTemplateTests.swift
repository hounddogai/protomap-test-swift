@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierTemplateTests {
    @Test func startsInOpen() throws {
        let item = Labs.newRegionalCourierTemplate("code-770", title: "title-93")
        #expect(item.status == Labs.RegionalCourierTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newRegionalCourierTemplate("code-770", title: "title-93")
        try item.moveTo(Labs.RegionalCourierTemplateStatus.resolved)
        #expect(item.status == Labs.RegionalCourierTemplateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newRegionalCourierTemplate("code-770", title: "title-93")
        item.status = Labs.RegionalCourierTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalCourierTemplateStatus.`open`) }
    }
}

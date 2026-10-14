@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachRecordTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newManualOutreachRecord("code-43", name: "name-621")
        #expect(item.status == CareManagement.ManualOutreachRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newManualOutreachRecord("code-43", name: "name-621")
        try item.moveTo(CareManagement.ManualOutreachRecordStatus.resolved)
        #expect(item.status == CareManagement.ManualOutreachRecordStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newManualOutreachRecord("code-43", name: "name-621")
        item.status = CareManagement.ManualOutreachRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachRecordStatus.`open`) }
    }
}

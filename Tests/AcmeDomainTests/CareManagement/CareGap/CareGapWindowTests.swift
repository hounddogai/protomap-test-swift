@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapWindowTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapWindow("code-80", name: "name-278")
        #expect(item.status == CareManagement.CareGapWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newCareGapWindow("code-80", name: "name-278")
        try item.moveTo(CareManagement.CareGapWindowStatus.archived)
        #expect(item.status == CareManagement.CareGapWindowStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapWindow("code-80", name: "name-278")
        item.status = CareManagement.CareGapWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapWindowStatus.`open`) }
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapGroupTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapGroup("code-661", label: "label-75")
        #expect(item.status == CareManagement.CareGapGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newCareGapGroup("code-661", label: "label-75")
        try item.moveTo(CareManagement.CareGapGroupStatus.resolved)
        #expect(item.status == CareManagement.CareGapGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapGroup("code-661", label: "label-75")
        item.status = CareManagement.CareGapGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapGroupStatus.`open`) }
    }
}

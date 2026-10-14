@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachRuleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newOutreachRule("code-991", title: "title-284")
        #expect(item.status == CareManagement.OutreachRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newOutreachRule("code-991", title: "title-284")
        try item.moveTo(CareManagement.OutreachRuleStatus.resolved)
        #expect(item.status == CareManagement.OutreachRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newOutreachRule("code-991", title: "title-284")
        item.status = CareManagement.OutreachRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachRuleStatus.`open`) }
    }
}

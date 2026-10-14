@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedOutreachTemplateTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCappedOutreachTemplate("code-105", label: "label-433")
        #expect(item.status == CareManagement.CappedOutreachTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newCappedOutreachTemplate("code-105", label: "label-433")
        try item.moveTo(CareManagement.CappedOutreachTemplateStatus.failed)
        #expect(item.status == CareManagement.CappedOutreachTemplateStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCappedOutreachTemplate("code-105", label: "label-433")
        item.status = CareManagement.CappedOutreachTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedOutreachTemplateStatus.new) }
    }
}

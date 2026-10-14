@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTemplateTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachTemplate("code-824", title: "title-644")
        #expect(item.status == CareManagement.OutreachTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newOutreachTemplate("code-824", title: "title-644")
        try item.moveTo(CareManagement.OutreachTemplateStatus.done)
        #expect(item.status == CareManagement.OutreachTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachTemplate("code-824", title: "title-644")
        item.status = CareManagement.OutreachTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachTemplateStatus.new) }
    }
}

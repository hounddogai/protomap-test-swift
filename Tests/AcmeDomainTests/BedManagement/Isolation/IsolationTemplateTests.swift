@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTemplateTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationTemplate("code-491", label: "label-566")
        #expect(item.status == BedManagement.IsolationTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newIsolationTemplate("code-491", label: "label-566")
        try item.moveTo(BedManagement.IsolationTemplateStatus.pending)
        #expect(item.status == BedManagement.IsolationTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationTemplate("code-491", label: "label-566")
        item.status = BedManagement.IsolationTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationTemplateStatus.draft) }
    }
}

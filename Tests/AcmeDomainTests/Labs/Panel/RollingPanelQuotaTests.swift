@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelQuotaTests {
    @Test func startsInNew() throws {
        let item = Labs.newRollingPanelQuota("code-262", title: "title-463")
        #expect(item.status == Labs.RollingPanelQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newRollingPanelQuota("code-262", title: "title-463")
        try item.moveTo(Labs.RollingPanelQuotaStatus.done)
        #expect(item.status == Labs.RollingPanelQuotaStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newRollingPanelQuota("code-262", title: "title-463")
        item.status = Labs.RollingPanelQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingPanelQuotaStatus.new) }
    }
}

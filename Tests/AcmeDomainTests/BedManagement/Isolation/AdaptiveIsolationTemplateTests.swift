@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationTemplateTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newAdaptiveIsolationTemplate("code-407", title: "title-44")
        #expect(item.status == BedManagement.AdaptiveIsolationTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newAdaptiveIsolationTemplate("code-407", title: "title-44")
        try item.moveTo(BedManagement.AdaptiveIsolationTemplateStatus.ready)
        #expect(item.status == BedManagement.AdaptiveIsolationTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newAdaptiveIsolationTemplate("code-407", title: "title-44")
        item.status = BedManagement.AdaptiveIsolationTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveIsolationTemplateStatus.idle) }
    }
}

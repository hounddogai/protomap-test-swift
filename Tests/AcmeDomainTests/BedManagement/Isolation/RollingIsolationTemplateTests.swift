@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationTemplateTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newRollingIsolationTemplate("code-887", label: "label-852")
        #expect(item.status == BedManagement.RollingIsolationTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newRollingIsolationTemplate("code-887", label: "label-852")
        try item.moveTo(BedManagement.RollingIsolationTemplateStatus.ready)
        #expect(item.status == BedManagement.RollingIsolationTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newRollingIsolationTemplate("code-887", label: "label-852")
        item.status = BedManagement.RollingIsolationTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingIsolationTemplateStatus.idle) }
    }
}

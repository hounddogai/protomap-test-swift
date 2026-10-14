@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationGroupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newFallbackIsolationGroup("code-846", label: "label-295")
        #expect(item.status == BedManagement.FallbackIsolationGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newFallbackIsolationGroup("code-846", label: "label-295")
        try item.moveTo(BedManagement.FallbackIsolationGroupStatus.queued)
        #expect(item.status == BedManagement.FallbackIsolationGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newFallbackIsolationGroup("code-846", label: "label-295")
        item.status = BedManagement.FallbackIsolationGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackIsolationGroupStatus.new) }
    }
}

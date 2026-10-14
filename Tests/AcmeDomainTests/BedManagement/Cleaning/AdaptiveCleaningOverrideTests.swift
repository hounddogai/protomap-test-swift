@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningOverrideTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newAdaptiveCleaningOverride("code-288", title: "title-155")
        #expect(item.status == BedManagement.AdaptiveCleaningOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newAdaptiveCleaningOverride("code-288", title: "title-155")
        try item.moveTo(BedManagement.AdaptiveCleaningOverrideStatus.running)
        #expect(item.status == BedManagement.AdaptiveCleaningOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newAdaptiveCleaningOverride("code-288", title: "title-155")
        item.status = BedManagement.AdaptiveCleaningOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningOverrideStatus.new) }
    }
}

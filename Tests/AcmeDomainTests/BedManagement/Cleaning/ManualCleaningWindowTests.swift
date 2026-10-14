@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningWindowTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newManualCleaningWindow("code-592", label: "label-769")
        #expect(item.status == BedManagement.ManualCleaningWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newManualCleaningWindow("code-592", label: "label-769")
        try item.moveTo(BedManagement.ManualCleaningWindowStatus.warming)
        #expect(item.status == BedManagement.ManualCleaningWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newManualCleaningWindow("code-592", label: "label-769")
        item.status = BedManagement.ManualCleaningWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCleaningWindowStatus.idle) }
    }
}

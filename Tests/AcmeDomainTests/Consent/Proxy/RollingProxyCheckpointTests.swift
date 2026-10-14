@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRollingProxyCheckpoint("code-277", label: "label-585")
        #expect(item.status == Consent.RollingProxyCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRollingProxyCheckpoint("code-277", label: "label-585")
        try item.moveTo(Consent.RollingProxyCheckpointStatus.scheduled)
        #expect(item.status == Consent.RollingProxyCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRollingProxyCheckpoint("code-277", label: "label-585")
        item.status = Consent.RollingProxyCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingProxyCheckpointStatus.planned) }
    }
}

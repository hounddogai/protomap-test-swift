@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAllocationTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRevocationAllocation("code-654", label: "label-477")
        #expect(item.status == Consent.RevocationAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newRevocationAllocation("code-654", label: "label-477")
        try item.moveTo(Consent.RevocationAllocationStatus.stopped)
        #expect(item.status == Consent.RevocationAllocationStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRevocationAllocation("code-654", label: "label-477")
        item.status = Consent.RevocationAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationAllocationStatus.idle) }
    }
}

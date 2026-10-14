@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAllocationTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessAllocation("code-728", title: "title-212")
        #expect(item.status == Consent.WitnessAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newWitnessAllocation("code-728", title: "title-212")
        try item.moveTo(Consent.WitnessAllocationStatus.ready)
        #expect(item.status == Consent.WitnessAllocationStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessAllocation("code-728", title: "title-212")
        item.status = Consent.WitnessAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessAllocationStatus.idle) }
    }
}

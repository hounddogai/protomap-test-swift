@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessQuotaTests {
    @Test func startsInIdle() throws {
        let item = Consent.newStrictWitnessQuota("code-204", title: "title-161")
        #expect(item.status == Consent.StrictWitnessQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newStrictWitnessQuota("code-204", title: "title-161")
        try item.moveTo(Consent.StrictWitnessQuotaStatus.ready)
        #expect(item.status == Consent.StrictWitnessQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newStrictWitnessQuota("code-204", title: "title-161")
        item.status = Consent.StrictWitnessQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictWitnessQuotaStatus.idle) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseAgreementTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newScheduledDispenseAgreement("code-290", title: "title-418")
        #expect(item.status == Pharmacy.ScheduledDispenseAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newScheduledDispenseAgreement("code-290", title: "title-418")
        try item.moveTo(Pharmacy.ScheduledDispenseAgreementStatus.draining)
        #expect(item.status == Pharmacy.ScheduledDispenseAgreementStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newScheduledDispenseAgreement("code-290", title: "title-418")
        item.status = Pharmacy.ScheduledDispenseAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledDispenseAgreementStatus.idle) }
    }
}

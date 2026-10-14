@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseAgreementTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRollingDispenseAgreement("code-876", title: "title-418")
        #expect(item.status == Pharmacy.RollingDispenseAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newRollingDispenseAgreement("code-876", title: "title-418")
        try item.moveTo(Pharmacy.RollingDispenseAgreementStatus.running)
        #expect(item.status == Pharmacy.RollingDispenseAgreementStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRollingDispenseAgreement("code-876", title: "title-418")
        item.status = Pharmacy.RollingDispenseAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingDispenseAgreementStatus.new) }
    }
}

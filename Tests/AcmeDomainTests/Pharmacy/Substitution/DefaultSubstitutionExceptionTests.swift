@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionExceptionTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDefaultSubstitutionException("code-945", label: "label-781")
        #expect(item.status == Pharmacy.DefaultSubstitutionExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newDefaultSubstitutionException("code-945", label: "label-781")
        try item.moveTo(Pharmacy.DefaultSubstitutionExceptionStatus.ready)
        #expect(item.status == Pharmacy.DefaultSubstitutionExceptionStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDefaultSubstitutionException("code-945", label: "label-781")
        item.status = Pharmacy.DefaultSubstitutionExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultSubstitutionExceptionStatus.idle) }
    }
}

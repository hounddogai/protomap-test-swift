@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseExceptionTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDefaultDispenseException("code-762", name: "name-648")
        #expect(item.status == Pharmacy.DefaultDispenseExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newDefaultDispenseException("code-762", name: "name-648")
        try item.moveTo(Pharmacy.DefaultDispenseExceptionStatus.validated)
        #expect(item.status == Pharmacy.DefaultDispenseExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDefaultDispenseException("code-762", name: "name-648")
        item.status = Pharmacy.DefaultDispenseExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultDispenseExceptionStatus.created) }
    }
}

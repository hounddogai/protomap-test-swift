@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallExceptionTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallException("code-737", name: "name-769")
        #expect(item.status == Pharmacy.RecallExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newRecallException("code-737", name: "name-769")
        try item.moveTo(Pharmacy.RecallExceptionStatus.done)
        #expect(item.status == Pharmacy.RecallExceptionStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallException("code-737", name: "name-769")
        item.status = Pharmacy.RecallExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallExceptionStatus.new) }
    }
}

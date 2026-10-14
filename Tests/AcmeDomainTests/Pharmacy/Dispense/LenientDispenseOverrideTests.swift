@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseOverrideTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newLenientDispenseOverride("code-985", title: "title-395")
        #expect(item.status == Pharmacy.LenientDispenseOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newLenientDispenseOverride("code-985", title: "title-395")
        try item.moveTo(Pharmacy.LenientDispenseOverrideStatus.suspended)
        #expect(item.status == Pharmacy.LenientDispenseOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newLenientDispenseOverride("code-985", title: "title-395")
        item.status = Pharmacy.LenientDispenseOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientDispenseOverrideStatus.draft) }
    }
}

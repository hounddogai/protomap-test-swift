@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseBundleTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLenientDispenseBundle("code-40", name: "name-620")
        #expect(item.status == Pharmacy.LenientDispenseBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newLenientDispenseBundle("code-40", name: "name-620")
        try item.moveTo(Pharmacy.LenientDispenseBundleStatus.cancelled)
        #expect(item.status == Pharmacy.LenientDispenseBundleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLenientDispenseBundle("code-40", name: "name-620")
        item.status = Pharmacy.LenientDispenseBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientDispenseBundleStatus.planned) }
    }
}

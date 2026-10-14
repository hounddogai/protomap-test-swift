@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyAllocationTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newStrictFormularyAllocation("code-104", label: "label-484")
        #expect(item.status == Pharmacy.StrictFormularyAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newStrictFormularyAllocation("code-104", label: "label-484")
        try item.moveTo(Pharmacy.StrictFormularyAllocationStatus.done)
        #expect(item.status == Pharmacy.StrictFormularyAllocationStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newStrictFormularyAllocation("code-104", label: "label-484")
        item.status = Pharmacy.StrictFormularyAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictFormularyAllocationStatus.new) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySegmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFormularySegment("code-990", label: "label-741")
        #expect(item.status == Pharmacy.FormularySegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newFormularySegment("code-990", label: "label-741")
        try item.moveTo(Pharmacy.FormularySegmentStatus.warming)
        #expect(item.status == Pharmacy.FormularySegmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFormularySegment("code-990", label: "label-741")
        item.status = Pharmacy.FormularySegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularySegmentStatus.idle) }
    }
}

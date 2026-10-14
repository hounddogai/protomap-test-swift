@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalFormularySegmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSeasonalFormularySegment("code-175", label: "label-424")
        #expect(item.status == Pharmacy.SeasonalFormularySegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newSeasonalFormularySegment("code-175", label: "label-424")
        try item.moveTo(Pharmacy.SeasonalFormularySegmentStatus.warming)
        #expect(item.status == Pharmacy.SeasonalFormularySegmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSeasonalFormularySegment("code-175", label: "label-424")
        item.status = Pharmacy.SeasonalFormularySegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalFormularySegmentStatus.idle) }
    }
}

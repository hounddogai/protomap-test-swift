@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedCensusWindowTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newWeightedCensusWindow("code-716", name: "name-245")
        #expect(item.status == BedManagement.WeightedCensusWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newWeightedCensusWindow("code-716", name: "name-245")
        try item.moveTo(BedManagement.WeightedCensusWindowStatus.failed)
        #expect(item.status == BedManagement.WeightedCensusWindowStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newWeightedCensusWindow("code-716", name: "name-245")
        item.status = BedManagement.WeightedCensusWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedCensusWindowStatus.new) }
    }
}

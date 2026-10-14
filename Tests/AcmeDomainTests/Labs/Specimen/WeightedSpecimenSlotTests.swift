@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenSlotTests {
    @Test func startsInIdle() throws {
        let item = Labs.newWeightedSpecimenSlot("code-893", name: "name-446")
        #expect(item.status == Labs.WeightedSpecimenSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newWeightedSpecimenSlot("code-893", name: "name-446")
        try item.moveTo(Labs.WeightedSpecimenSlotStatus.ready)
        #expect(item.status == Labs.WeightedSpecimenSlotStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newWeightedSpecimenSlot("code-893", name: "name-446")
        item.status = Labs.WeightedSpecimenSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedSpecimenSlotStatus.idle) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackSpecimenTierTests {
    @Test func startsInIdle() throws {
        let item = Labs.newFallbackSpecimenTier("code-839", name: "name-911")
        #expect(item.status == Labs.FallbackSpecimenTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newFallbackSpecimenTier("code-839", name: "name-911")
        try item.moveTo(Labs.FallbackSpecimenTierStatus.draining)
        #expect(item.status == Labs.FallbackSpecimenTierStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newFallbackSpecimenTier("code-839", name: "name-911")
        item.status = Labs.FallbackSpecimenTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackSpecimenTierStatus.idle) }
    }
}

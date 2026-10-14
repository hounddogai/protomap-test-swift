@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        #expect(item.status == Imaging.BatchedPriorityPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        try item.moveTo(Imaging.BatchedPriorityPreferenceStatus.withdrawn)
        #expect(item.status == Imaging.BatchedPriorityPreferenceStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        item.status = Imaging.BatchedPriorityPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedPriorityPreferenceStatus.proposed) }
    }
}

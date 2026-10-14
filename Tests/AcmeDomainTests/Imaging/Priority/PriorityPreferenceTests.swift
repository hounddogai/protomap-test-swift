@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityPreference("code-469", name: "name-731")
        #expect(item.status == Imaging.PriorityPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newPriorityPreference("code-469", name: "name-731")
        try item.moveTo(Imaging.PriorityPreferenceStatus.rejected)
        #expect(item.status == Imaging.PriorityPreferenceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityPreference("code-469", name: "name-731")
        item.status = Imaging.PriorityPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityPreferenceStatus.proposed) }
    }
}

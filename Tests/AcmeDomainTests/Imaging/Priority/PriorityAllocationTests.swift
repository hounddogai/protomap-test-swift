@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAllocationTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityAllocation("code-299", title: "title-456")
        #expect(item.status == Imaging.PriorityAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newPriorityAllocation("code-299", title: "title-456")
        try item.moveTo(Imaging.PriorityAllocationStatus.rejected)
        #expect(item.status == Imaging.PriorityAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityAllocation("code-299", title: "title-456")
        item.status = Imaging.PriorityAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityAllocationStatus.proposed) }
    }
}

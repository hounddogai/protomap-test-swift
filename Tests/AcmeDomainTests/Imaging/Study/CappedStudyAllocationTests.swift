@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedStudyAllocationTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newCappedStudyAllocation("code-248", label: "label-521")
        #expect(item.status == Imaging.CappedStudyAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newCappedStudyAllocation("code-248", label: "label-521")
        try item.moveTo(Imaging.CappedStudyAllocationStatus.approved)
        #expect(item.status == Imaging.CappedStudyAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newCappedStudyAllocation("code-248", label: "label-521")
        item.status = Imaging.CappedStudyAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedStudyAllocationStatus.proposed) }
    }
}

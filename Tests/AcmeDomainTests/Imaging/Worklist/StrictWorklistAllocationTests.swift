@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistAllocationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newStrictWorklistAllocation("code-404", name: "name-175")
        #expect(item.status == Imaging.StrictWorklistAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newStrictWorklistAllocation("code-404", name: "name-175")
        try item.moveTo(Imaging.StrictWorklistAllocationStatus.revoked)
        #expect(item.status == Imaging.StrictWorklistAllocationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newStrictWorklistAllocation("code-404", name: "name-175")
        item.status = Imaging.StrictWorklistAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictWorklistAllocationStatus.requested) }
    }
}

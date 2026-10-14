@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAllocationTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newCareProtocolAllocation("code-737", name: "name-110")
        #expect(item.status == Imaging.CareProtocolAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newCareProtocolAllocation("code-737", name: "name-110")
        try item.moveTo(Imaging.CareProtocolAllocationStatus.inReview)
        #expect(item.status == Imaging.CareProtocolAllocationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newCareProtocolAllocation("code-737", name: "name-110")
        item.status = Imaging.CareProtocolAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolAllocationStatus.`open`) }
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolAllocationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newTieredCareProtocolAllocation("code-192", title: "title-567")
        #expect(item.status == Imaging.TieredCareProtocolAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newTieredCareProtocolAllocation("code-192", title: "title-567")
        try item.moveTo(Imaging.TieredCareProtocolAllocationStatus.granted)
        #expect(item.status == Imaging.TieredCareProtocolAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newTieredCareProtocolAllocation("code-192", title: "title-567")
        item.status = Imaging.TieredCareProtocolAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredCareProtocolAllocationStatus.requested) }
    }
}

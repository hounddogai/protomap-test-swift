@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAllocationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newDefaultCareProtocolAllocation("code-647", title: "title-806")
        #expect(item.status == Imaging.DefaultCareProtocolAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newDefaultCareProtocolAllocation("code-647", title: "title-806")
        try item.moveTo(Imaging.DefaultCareProtocolAllocationStatus.revoked)
        #expect(item.status == Imaging.DefaultCareProtocolAllocationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newDefaultCareProtocolAllocation("code-647", title: "title-806")
        item.status = Imaging.DefaultCareProtocolAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultCareProtocolAllocationStatus.requested) }
    }
}

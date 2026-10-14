@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialSegmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newFallbackCredentialSegment("code-132", title: "title-169")
        #expect(item.status == Staffing.FallbackCredentialSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newFallbackCredentialSegment("code-132", title: "title-169")
        try item.moveTo(Staffing.FallbackCredentialSegmentStatus.revoked)
        #expect(item.status == Staffing.FallbackCredentialSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newFallbackCredentialSegment("code-132", title: "title-169")
        item.status = Staffing.FallbackCredentialSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackCredentialSegmentStatus.requested) }
    }
}

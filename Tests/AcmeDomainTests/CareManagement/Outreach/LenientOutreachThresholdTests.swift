@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachThresholdTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newLenientOutreachThreshold("code-634", name: "name-961")
        #expect(item.status == CareManagement.LenientOutreachThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newLenientOutreachThreshold("code-634", name: "name-961")
        try item.moveTo(CareManagement.LenientOutreachThresholdStatus.revoked)
        #expect(item.status == CareManagement.LenientOutreachThresholdStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newLenientOutreachThreshold("code-634", name: "name-961")
        item.status = CareManagement.LenientOutreachThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachThresholdStatus.requested) }
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapPolicyTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newTieredCareGapPolicy("code-258", name: "name-440")
        #expect(item.status == CareManagement.TieredCareGapPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newTieredCareGapPolicy("code-258", name: "name-440")
        try item.moveTo(CareManagement.TieredCareGapPolicyStatus.stopped)
        #expect(item.status == CareManagement.TieredCareGapPolicyStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newTieredCareGapPolicy("code-258", name: "name-440")
        item.status = CareManagement.TieredCareGapPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredCareGapPolicyStatus.idle) }
    }
}

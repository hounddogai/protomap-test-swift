@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalRiskScoreTierTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newGlobalRiskScoreTier("code-451", title: "title-304")
        #expect(item.status == CareManagement.GlobalRiskScoreTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newGlobalRiskScoreTier("code-451", title: "title-304")
        try item.moveTo(CareManagement.GlobalRiskScoreTierStatus.granted)
        #expect(item.status == CareManagement.GlobalRiskScoreTierStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newGlobalRiskScoreTier("code-451", title: "title-304")
        item.status = CareManagement.GlobalRiskScoreTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalRiskScoreTierStatus.requested) }
    }
}

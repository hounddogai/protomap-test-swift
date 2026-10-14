@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreWindowTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        #expect(item.status == CareManagement.DefaultRiskScoreWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        try item.moveTo(CareManagement.DefaultRiskScoreWindowStatus.active)
        #expect(item.status == CareManagement.DefaultRiskScoreWindowStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        item.status = CareManagement.DefaultRiskScoreWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultRiskScoreWindowStatus.draft) }
    }
}

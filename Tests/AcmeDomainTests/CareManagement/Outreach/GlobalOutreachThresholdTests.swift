@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachThresholdTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGlobalOutreachThreshold("code-670", name: "name-883")
        #expect(item.status == CareManagement.GlobalOutreachThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newGlobalOutreachThreshold("code-670", name: "name-883")
        try item.moveTo(CareManagement.GlobalOutreachThresholdStatus.scheduled)
        #expect(item.status == CareManagement.GlobalOutreachThresholdStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGlobalOutreachThreshold("code-670", name: "name-883")
        item.status = CareManagement.GlobalOutreachThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalOutreachThresholdStatus.planned) }
    }
}

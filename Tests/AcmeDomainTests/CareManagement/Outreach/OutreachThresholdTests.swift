@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachThresholdTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachThreshold("code-30", title: "title-831")
        #expect(item.status == CareManagement.OutreachThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newOutreachThreshold("code-30", title: "title-831")
        try item.moveTo(CareManagement.OutreachThresholdStatus.queued)
        #expect(item.status == CareManagement.OutreachThresholdStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachThreshold("code-30", title: "title-831")
        item.status = CareManagement.OutreachThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachThresholdStatus.new) }
    }
}

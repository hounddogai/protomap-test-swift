@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityQuotaTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPriorityQuota("code-973", label: "label-100")
        #expect(item.status == Imaging.PriorityQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newPriorityQuota("code-973", label: "label-100")
        try item.moveTo(Imaging.PriorityQuotaStatus.queued)
        #expect(item.status == Imaging.PriorityQuotaStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPriorityQuota("code-973", label: "label-100")
        item.status = Imaging.PriorityQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityQuotaStatus.new) }
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityQuotaTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newGlobalPriorityQuota("code-796", label: "label-698")
        #expect(item.status == Imaging.GlobalPriorityQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newGlobalPriorityQuota("code-796", label: "label-698")
        try item.moveTo(Imaging.GlobalPriorityQuotaStatus.published)
        #expect(item.status == Imaging.GlobalPriorityQuotaStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newGlobalPriorityQuota("code-796", label: "label-698")
        item.status = Imaging.GlobalPriorityQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalPriorityQuotaStatus.created) }
    }
}

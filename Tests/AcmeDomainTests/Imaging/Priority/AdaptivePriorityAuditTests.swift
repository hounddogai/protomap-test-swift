@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityAuditTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newAdaptivePriorityAudit("code-54", name: "name-128")
        #expect(item.status == Imaging.AdaptivePriorityAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newAdaptivePriorityAudit("code-54", name: "name-128")
        try item.moveTo(Imaging.AdaptivePriorityAuditStatus.expired)
        #expect(item.status == Imaging.AdaptivePriorityAuditStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newAdaptivePriorityAudit("code-54", name: "name-128")
        item.status = Imaging.AdaptivePriorityAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptivePriorityAuditStatus.requested) }
    }
}

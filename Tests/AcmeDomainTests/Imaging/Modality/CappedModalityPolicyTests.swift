@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityPolicyTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCappedModalityPolicy("code-618", label: "label-354")
        #expect(item.status == Imaging.CappedModalityPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newCappedModalityPolicy("code-618", label: "label-354")
        try item.moveTo(Imaging.CappedModalityPolicyStatus.suspended)
        #expect(item.status == Imaging.CappedModalityPolicyStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCappedModalityPolicy("code-618", label: "label-354")
        item.status = Imaging.CappedModalityPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityPolicyStatus.draft) }
    }
}

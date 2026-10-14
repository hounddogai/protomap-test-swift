@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTargetTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newReadTarget("code-56", label: "label-77")
        #expect(item.status == Imaging.ReadTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newReadTarget("code-56", label: "label-77")
        try item.moveTo(Imaging.ReadTargetStatus.reopened)
        #expect(item.status == Imaging.ReadTargetStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newReadTarget("code-56", label: "label-77")
        item.status = Imaging.ReadTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadTargetStatus.`open`) }
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBaselineTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRegionalStudyBaseline("code-639", name: "name-657")
        #expect(item.status == Imaging.RegionalStudyBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newRegionalStudyBaseline("code-639", name: "name-657")
        try item.moveTo(Imaging.RegionalStudyBaselineStatus.running)
        #expect(item.status == Imaging.RegionalStudyBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRegionalStudyBaseline("code-639", name: "name-657")
        item.status = Imaging.RegionalStudyBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyBaselineStatus.new) }
    }
}

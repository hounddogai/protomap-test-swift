@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultReadBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newDefaultReadBaseline("code-880", name: "name-788")
        #expect(item.status == Imaging.DefaultReadBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newDefaultReadBaseline("code-880", name: "name-788")
        try item.moveTo(Imaging.DefaultReadBaselineStatus.scheduled)
        #expect(item.status == Imaging.DefaultReadBaselineStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newDefaultReadBaseline("code-880", name: "name-788")
        item.status = Imaging.DefaultReadBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultReadBaselineStatus.planned) }
    }
}

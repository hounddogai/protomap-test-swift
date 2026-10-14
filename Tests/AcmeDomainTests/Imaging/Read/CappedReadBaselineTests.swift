@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedReadBaselineTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newCappedReadBaseline("code-909", name: "name-224")
        #expect(item.status == Imaging.CappedReadBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newCappedReadBaseline("code-909", name: "name-224")
        try item.moveTo(Imaging.CappedReadBaselineStatus.resolved)
        #expect(item.status == Imaging.CappedReadBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newCappedReadBaseline("code-909", name: "name-224")
        item.status = Imaging.CappedReadBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedReadBaselineStatus.`open`) }
    }
}

@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMappingTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWorklistMapping("code-477", name: "name-570")
        #expect(item.status == Imaging.WorklistMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newWorklistMapping("code-477", name: "name-570")
        try item.moveTo(Imaging.WorklistMappingStatus.resolved)
        #expect(item.status == Imaging.WorklistMappingStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWorklistMapping("code-477", name: "name-570")
        item.status = Imaging.WorklistMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistMappingStatus.`open`) }
    }
}

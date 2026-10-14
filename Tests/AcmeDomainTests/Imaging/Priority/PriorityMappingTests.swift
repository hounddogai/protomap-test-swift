@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityMappingTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPriorityMapping("code-308", name: "name-330")
        #expect(item.status == Imaging.PriorityMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newPriorityMapping("code-308", name: "name-330")
        try item.moveTo(Imaging.PriorityMappingStatus.reopened)
        #expect(item.status == Imaging.PriorityMappingStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPriorityMapping("code-308", name: "name-330")
        item.status = Imaging.PriorityMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityMappingStatus.`open`) }
    }
}

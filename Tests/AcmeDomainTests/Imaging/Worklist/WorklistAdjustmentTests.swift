@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWorklistAdjustment("code-647", name: "name-51")
        #expect(item.status == Imaging.WorklistAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newWorklistAdjustment("code-647", name: "name-51")
        try item.moveTo(Imaging.WorklistAdjustmentStatus.archived)
        #expect(item.status == Imaging.WorklistAdjustmentStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWorklistAdjustment("code-647", name: "name-51")
        item.status = Imaging.WorklistAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistAdjustmentStatus.`open`) }
    }
}

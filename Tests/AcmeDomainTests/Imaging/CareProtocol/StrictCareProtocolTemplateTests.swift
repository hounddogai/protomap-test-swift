@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        #expect(item.status == Imaging.StrictCareProtocolTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        try item.moveTo(Imaging.StrictCareProtocolTemplateStatus.inProgress)
        #expect(item.status == Imaging.StrictCareProtocolTemplateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        item.status = Imaging.StrictCareProtocolTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictCareProtocolTemplateStatus.planned) }
    }
}

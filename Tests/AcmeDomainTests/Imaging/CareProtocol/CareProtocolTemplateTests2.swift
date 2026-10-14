@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTemplateTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolTemplate("code-317", label: "label-907")
        #expect(item.status == Imaging.CareProtocolTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newCareProtocolTemplate("code-317", label: "label-907")
        try item.moveTo(Imaging.CareProtocolTemplateStatus.queued)
        #expect(item.status == Imaging.CareProtocolTemplateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolTemplate("code-317", label: "label-907")
        item.status = Imaging.CareProtocolTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolTemplateStatus.new) }
    }
}

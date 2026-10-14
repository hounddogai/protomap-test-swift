@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientWorklistTemplateTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newLenientWorklistTemplate("code-882", label: "label-821")
        #expect(item.status == Imaging.LenientWorklistTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newLenientWorklistTemplate("code-882", label: "label-821")
        try item.moveTo(Imaging.LenientWorklistTemplateStatus.granted)
        #expect(item.status == Imaging.LenientWorklistTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newLenientWorklistTemplate("code-882", label: "label-821")
        item.status = Imaging.LenientWorklistTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientWorklistTemplateStatus.requested) }
    }
}

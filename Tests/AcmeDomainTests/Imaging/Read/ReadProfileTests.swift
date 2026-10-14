@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadProfileTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newReadProfile("code-895", title: "title-645")
        #expect(item.status == Imaging.ReadProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newReadProfile("code-895", title: "title-645")
        try item.moveTo(Imaging.ReadProfileStatus.scheduled)
        #expect(item.status == Imaging.ReadProfileStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newReadProfile("code-895", title: "title-645")
        item.status = Imaging.ReadProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadProfileStatus.planned) }
    }
}

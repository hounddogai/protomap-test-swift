@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRequestTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newReadRequest("code-666", name: "name-593")
        #expect(item.status == Imaging.ReadRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newReadRequest("code-666", name: "name-593")
        try item.moveTo(Imaging.ReadRequestStatus.scheduled)
        #expect(item.status == Imaging.ReadRequestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newReadRequest("code-666", name: "name-593")
        item.status = Imaging.ReadRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadRequestStatus.planned) }
    }
}

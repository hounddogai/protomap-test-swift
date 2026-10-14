@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierMappingTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCourierMapping("code-848", name: "name-653")
        #expect(item.status == Labs.CourierMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newCourierMapping("code-848", name: "name-653")
        try item.moveTo(Labs.CourierMappingStatus.pending)
        #expect(item.status == Labs.CourierMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCourierMapping("code-848", name: "name-653")
        item.status = Labs.CourierMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierMappingStatus.draft) }
    }
}

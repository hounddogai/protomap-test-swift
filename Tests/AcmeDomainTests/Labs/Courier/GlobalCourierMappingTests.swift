@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMappingTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newGlobalCourierMapping("code-978", title: "title-554")
        #expect(item.status == Labs.GlobalCourierMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newGlobalCourierMapping("code-978", title: "title-554")
        try item.moveTo(Labs.GlobalCourierMappingStatus.scheduled)
        #expect(item.status == Labs.GlobalCourierMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newGlobalCourierMapping("code-978", title: "title-554")
        item.status = Labs.GlobalCourierMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalCourierMappingStatus.planned) }
    }
}

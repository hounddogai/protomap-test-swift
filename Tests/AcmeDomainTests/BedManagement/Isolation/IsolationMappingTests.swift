@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMappingTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newIsolationMapping("code-843", title: "title-28")
        #expect(item.status == BedManagement.IsolationMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = BedManagement.newIsolationMapping("code-843", title: "title-28")
        try item.moveTo(BedManagement.IsolationMappingStatus.cancelled)
        #expect(item.status == BedManagement.IsolationMappingStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newIsolationMapping("code-843", title: "title-28")
        item.status = BedManagement.IsolationMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationMappingStatus.planned) }
    }
}

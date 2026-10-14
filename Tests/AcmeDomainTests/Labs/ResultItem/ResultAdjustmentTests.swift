@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultAdjustment("code-604", name: "name-292")
        #expect(item.status == Labs.ResultAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newResultAdjustment("code-604", name: "name-292")
        try item.moveTo(Labs.ResultAdjustmentStatus.revoked)
        #expect(item.status == Labs.ResultAdjustmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultAdjustment("code-604", name: "name-292")
        item.status = Labs.ResultAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultAdjustmentStatus.requested) }
    }
}

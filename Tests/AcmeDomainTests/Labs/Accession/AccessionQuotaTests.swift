@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionQuotaTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionQuota("code-11", name: "name-491")
        #expect(item.status == Labs.AccessionQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newAccessionQuota("code-11", name: "name-491")
        try item.moveTo(Labs.AccessionQuotaStatus.ready)
        #expect(item.status == Labs.AccessionQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionQuota("code-11", name: "name-491")
        item.status = Labs.AccessionQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionQuotaStatus.idle) }
    }
}

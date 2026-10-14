@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultQuotaTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultQuota("code-32", label: "label-594")
        #expect(item.status == Labs.ResultQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newResultQuota("code-32", label: "label-594")
        try item.moveTo(Labs.ResultQuotaStatus.expired)
        #expect(item.status == Labs.ResultQuotaStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultQuota("code-32", label: "label-594")
        item.status = Labs.ResultQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultQuotaStatus.requested) }
    }
}

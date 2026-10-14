@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultVarianceTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultVariance("code-517", title: "title-637")
        #expect(item.status == Labs.ResultVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newResultVariance("code-517", title: "title-637")
        try item.moveTo(Labs.ResultVarianceStatus.revoked)
        #expect(item.status == Labs.ResultVarianceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultVariance("code-517", title: "title-637")
        item.status = Labs.ResultVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultVarianceStatus.requested) }
    }
}

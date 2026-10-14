@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceDigestTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceDigest("code-660", name: "name-80")
        #expect(item.status == RevenueCycle.RemittanceDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newRemittanceDigest("code-660", name: "name-80")
        try item.moveTo(RevenueCycle.RemittanceDigestStatus.scheduled)
        #expect(item.status == RevenueCycle.RemittanceDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceDigest("code-660", name: "name-80")
        item.status = RevenueCycle.RemittanceDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceDigestStatus.planned) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceDigestTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDefaultRemittanceDigest("code-400", name: "name-507")
        #expect(item.status == RevenueCycle.DefaultRemittanceDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newDefaultRemittanceDigest("code-400", name: "name-507")
        try item.moveTo(RevenueCycle.DefaultRemittanceDigestStatus.scheduled)
        #expect(item.status == RevenueCycle.DefaultRemittanceDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDefaultRemittanceDigest("code-400", name: "name-507")
        item.status = RevenueCycle.DefaultRemittanceDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultRemittanceDigestStatus.planned) }
    }
}

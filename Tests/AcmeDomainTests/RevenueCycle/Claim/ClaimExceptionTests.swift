@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimExceptionTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newClaimException("code-419", title: "title-623")
        #expect(item.status == RevenueCycle.ClaimExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newClaimException("code-419", title: "title-623")
        try item.moveTo(RevenueCycle.ClaimExceptionStatus.warming)
        #expect(item.status == RevenueCycle.ClaimExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newClaimException("code-419", title: "title-623")
        item.status = RevenueCycle.ClaimExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimExceptionStatus.idle) }
    }
}

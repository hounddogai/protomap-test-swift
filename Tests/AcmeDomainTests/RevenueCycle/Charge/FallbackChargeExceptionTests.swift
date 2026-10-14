@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeExceptionTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newFallbackChargeException("code-989", title: "title-943")
        #expect(item.status == RevenueCycle.FallbackChargeExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newFallbackChargeException("code-989", title: "title-943")
        try item.moveTo(RevenueCycle.FallbackChargeExceptionStatus.draining)
        #expect(item.status == RevenueCycle.FallbackChargeExceptionStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newFallbackChargeException("code-989", title: "title-943")
        item.status = RevenueCycle.FallbackChargeExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackChargeExceptionStatus.idle) }
    }
}

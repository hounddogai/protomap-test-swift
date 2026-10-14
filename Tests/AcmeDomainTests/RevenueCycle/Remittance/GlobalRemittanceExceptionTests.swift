@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalRemittanceExceptionTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        #expect(item.status == RevenueCycle.GlobalRemittanceExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        try item.moveTo(RevenueCycle.GlobalRemittanceExceptionStatus.warming)
        #expect(item.status == RevenueCycle.GlobalRemittanceExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        item.status = RevenueCycle.GlobalRemittanceExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalRemittanceExceptionStatus.idle) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBatchTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceBatch("code-389", name: "name-81")
        #expect(item.status == RevenueCycle.RemittanceBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRemittanceBatch("code-389", name: "name-81")
        try item.moveTo(RevenueCycle.RemittanceBatchStatus.warming)
        #expect(item.status == RevenueCycle.RemittanceBatchStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceBatch("code-389", name: "name-81")
        item.status = RevenueCycle.RemittanceBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceBatchStatus.idle) }
    }
}

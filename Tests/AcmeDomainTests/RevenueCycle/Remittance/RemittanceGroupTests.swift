@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceGroupTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceGroup("code-935", name: "name-762")
        #expect(item.status == RevenueCycle.RemittanceGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newRemittanceGroup("code-935", name: "name-762")
        try item.moveTo(RevenueCycle.RemittanceGroupStatus.completed)
        #expect(item.status == RevenueCycle.RemittanceGroupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceGroup("code-935", name: "name-762")
        item.status = RevenueCycle.RemittanceGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceGroupStatus.planned) }
    }
}

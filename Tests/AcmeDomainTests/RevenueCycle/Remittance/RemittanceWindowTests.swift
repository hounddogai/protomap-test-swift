@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceWindowTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceWindow("code-322", title: "title-155")
        #expect(item.status == RevenueCycle.RemittanceWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newRemittanceWindow("code-322", title: "title-155")
        try item.moveTo(RevenueCycle.RemittanceWindowStatus.cancelled)
        #expect(item.status == RevenueCycle.RemittanceWindowStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceWindow("code-322", title: "title-155")
        item.status = RevenueCycle.RemittanceWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceWindowStatus.planned) }
    }
}

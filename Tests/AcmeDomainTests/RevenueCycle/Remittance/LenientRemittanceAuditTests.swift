@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceAuditTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLenientRemittanceAudit("code-934", title: "title-62")
        #expect(item.status == RevenueCycle.LenientRemittanceAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newLenientRemittanceAudit("code-934", title: "title-62")
        try item.moveTo(RevenueCycle.LenientRemittanceAuditStatus.validated)
        #expect(item.status == RevenueCycle.LenientRemittanceAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLenientRemittanceAudit("code-934", title: "title-62")
        item.status = RevenueCycle.LenientRemittanceAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientRemittanceAuditStatus.created) }
    }
}

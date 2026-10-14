@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientChargeTierTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLenientChargeTier("code-655", label: "label-258")
        #expect(item.status == RevenueCycle.LenientChargeTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newLenientChargeTier("code-655", label: "label-258")
        try item.moveTo(RevenueCycle.LenientChargeTierStatus.closed)
        #expect(item.status == RevenueCycle.LenientChargeTierStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLenientChargeTier("code-655", label: "label-258")
        item.status = RevenueCycle.LenientChargeTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientChargeTierStatus.draft) }
    }
}

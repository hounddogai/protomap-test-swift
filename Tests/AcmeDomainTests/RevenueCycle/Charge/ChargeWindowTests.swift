@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeWindowTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeWindow("code-483", title: "title-947")
        #expect(item.status == RevenueCycle.ChargeWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newChargeWindow("code-483", title: "title-947")
        try item.moveTo(RevenueCycle.ChargeWindowStatus.granted)
        #expect(item.status == RevenueCycle.ChargeWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeWindow("code-483", title: "title-947")
        item.status = RevenueCycle.ChargeWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeWindowStatus.requested) }
    }
}

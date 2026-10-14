@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeManifestTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeManifest("code-784", title: "title-530")
        #expect(item.status == RevenueCycle.ChargeManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = RevenueCycle.newChargeManifest("code-784", title: "title-530")
        try item.moveTo(RevenueCycle.ChargeManifestStatus.expired)
        #expect(item.status == RevenueCycle.ChargeManifestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeManifest("code-784", title: "title-530")
        item.status = RevenueCycle.ChargeManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeManifestStatus.requested) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictChargeGroupTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStrictChargeGroup("code-491", title: "title-718")
        #expect(item.status == RevenueCycle.StrictChargeGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newStrictChargeGroup("code-491", title: "title-718")
        try item.moveTo(RevenueCycle.StrictChargeGroupStatus.validated)
        #expect(item.status == RevenueCycle.StrictChargeGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStrictChargeGroup("code-491", title: "title-718")
        item.status = RevenueCycle.StrictChargeGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictChargeGroupStatus.created) }
    }
}

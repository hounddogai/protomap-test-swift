@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialMappingTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newStrictDenialMapping("code-432", name: "name-28")
        #expect(item.status == RevenueCycle.StrictDenialMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newStrictDenialMapping("code-432", name: "name-28")
        try item.moveTo(RevenueCycle.StrictDenialMappingStatus.inProgress)
        #expect(item.status == RevenueCycle.StrictDenialMappingStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newStrictDenialMapping("code-432", name: "name-28")
        item.status = RevenueCycle.StrictDenialMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictDenialMappingStatus.planned) }
    }
}

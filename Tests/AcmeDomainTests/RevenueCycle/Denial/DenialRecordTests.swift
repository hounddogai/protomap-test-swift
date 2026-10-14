@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRecordTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialRecord("code-471", name: "name-631")
        #expect(item.status == RevenueCycle.DenialRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newDenialRecord("code-471", name: "name-631")
        try item.moveTo(RevenueCycle.DenialRecordStatus.withdrawn)
        #expect(item.status == RevenueCycle.DenialRecordStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialRecord("code-471", name: "name-631")
        item.status = RevenueCycle.DenialRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialRecordStatus.proposed) }
    }
}

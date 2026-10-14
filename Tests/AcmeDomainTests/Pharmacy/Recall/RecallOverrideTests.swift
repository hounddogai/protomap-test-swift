@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallOverrideTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRecallOverride("code-650", name: "name-847")
        #expect(item.status == Pharmacy.RecallOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newRecallOverride("code-650", name: "name-847")
        try item.moveTo(Pharmacy.RecallOverrideStatus.published)
        #expect(item.status == Pharmacy.RecallOverrideStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRecallOverride("code-650", name: "name-847")
        item.status = Pharmacy.RecallOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallOverrideStatus.created) }
    }
}

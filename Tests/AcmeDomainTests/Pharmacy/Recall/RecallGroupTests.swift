@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallGroupTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newRecallGroup("code-239", name: "name-987")
        #expect(item.status == Pharmacy.RecallGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newRecallGroup("code-239", name: "name-987")
        try item.moveTo(Pharmacy.RecallGroupStatus.suspended)
        #expect(item.status == Pharmacy.RecallGroupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newRecallGroup("code-239", name: "name-987")
        item.status = Pharmacy.RecallGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallGroupStatus.draft) }
    }
}

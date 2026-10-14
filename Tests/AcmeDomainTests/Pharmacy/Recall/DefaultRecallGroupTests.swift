@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallGroupTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newDefaultRecallGroup("code-127", title: "title-817")
        #expect(item.status == Pharmacy.DefaultRecallGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newDefaultRecallGroup("code-127", title: "title-817")
        try item.moveTo(Pharmacy.DefaultRecallGroupStatus.reopened)
        #expect(item.status == Pharmacy.DefaultRecallGroupStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newDefaultRecallGroup("code-127", title: "title-817")
        item.status = Pharmacy.DefaultRecallGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultRecallGroupStatus.`open`) }
    }
}

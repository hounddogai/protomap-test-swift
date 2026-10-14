@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallOverrideTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRegionalRecallOverride("code-610", label: "label-393")
        #expect(item.status == Pharmacy.RegionalRecallOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRegionalRecallOverride("code-610", label: "label-393")
        try item.moveTo(Pharmacy.RegionalRecallOverrideStatus.inReview)
        #expect(item.status == Pharmacy.RegionalRecallOverrideStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRegionalRecallOverride("code-610", label: "label-393")
        item.status = Pharmacy.RegionalRecallOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalRecallOverrideStatus.`open`) }
    }
}

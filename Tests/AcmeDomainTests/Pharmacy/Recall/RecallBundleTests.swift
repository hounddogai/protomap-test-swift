@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBundleTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallBundle("code-591", label: "label-709")
        #expect(item.status == Pharmacy.RecallBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newRecallBundle("code-591", label: "label-709")
        try item.moveTo(Pharmacy.RecallBundleStatus.resolved)
        #expect(item.status == Pharmacy.RecallBundleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallBundle("code-591", label: "label-709")
        item.status = Pharmacy.RecallBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallBundleStatus.`open`) }
    }
}

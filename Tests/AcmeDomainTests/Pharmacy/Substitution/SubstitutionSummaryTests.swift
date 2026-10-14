@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSummaryTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSubstitutionSummary("code-629", name: "name-444")
        #expect(item.status == Pharmacy.SubstitutionSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newSubstitutionSummary("code-629", name: "name-444")
        try item.moveTo(Pharmacy.SubstitutionSummaryStatus.draining)
        #expect(item.status == Pharmacy.SubstitutionSummaryStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSubstitutionSummary("code-629", name: "name-444")
        item.status = Pharmacy.SubstitutionSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionSummaryStatus.idle) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalDispenseSummaryTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newGlobalDispenseSummary("code-281", title: "title-721")
        #expect(item.status == Pharmacy.GlobalDispenseSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newGlobalDispenseSummary("code-281", title: "title-721")
        try item.moveTo(Pharmacy.GlobalDispenseSummaryStatus.validated)
        #expect(item.status == Pharmacy.GlobalDispenseSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newGlobalDispenseSummary("code-281", title: "title-721")
        item.status = Pharmacy.GlobalDispenseSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalDispenseSummaryStatus.created) }
    }
}

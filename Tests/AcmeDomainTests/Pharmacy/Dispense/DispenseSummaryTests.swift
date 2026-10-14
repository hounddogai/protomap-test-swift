@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSummaryTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newDispenseSummary("code-721", title: "title-849")
        #expect(item.status == Pharmacy.DispenseSummaryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newDispenseSummary("code-721", title: "title-849")
        try item.moveTo(Pharmacy.DispenseSummaryStatus.resolved)
        #expect(item.status == Pharmacy.DispenseSummaryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newDispenseSummary("code-721", title: "title-849")
        item.status = Pharmacy.DispenseSummaryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseSummaryStatus.`open`) }
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningSummaryTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newRollingCleaningSummary("code-386", title: "title-348")
        #expect(item.status == BedManagement.RollingCleaningSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newRollingCleaningSummary("code-386", title: "title-348")
        try item.moveTo(BedManagement.RollingCleaningSummaryStatus.validated)
        #expect(item.status == BedManagement.RollingCleaningSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newRollingCleaningSummary("code-386", title: "title-348")
        item.status = BedManagement.RollingCleaningSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCleaningSummaryStatus.created) }
    }
}

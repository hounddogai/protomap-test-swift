@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationEstimateTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationEstimate("code-924", title: "title-85")
        #expect(item.status == BedManagement.IsolationEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newIsolationEstimate("code-924", title: "title-85")
        try item.moveTo(BedManagement.IsolationEstimateStatus.archived)
        #expect(item.status == BedManagement.IsolationEstimateStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationEstimate("code-924", title: "title-85")
        item.status = BedManagement.IsolationEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationEstimateStatus.`open`) }
    }
}

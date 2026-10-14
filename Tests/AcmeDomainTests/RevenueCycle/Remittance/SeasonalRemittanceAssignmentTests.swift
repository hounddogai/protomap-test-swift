@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalRemittanceAssignmentTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        #expect(item.status == RevenueCycle.SeasonalRemittanceAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        try item.moveTo(RevenueCycle.SeasonalRemittanceAssignmentStatus.archived)
        #expect(item.status == RevenueCycle.SeasonalRemittanceAssignmentStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        item.status = RevenueCycle.SeasonalRemittanceAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.SeasonalRemittanceAssignmentStatus.`open`) }
    }
}

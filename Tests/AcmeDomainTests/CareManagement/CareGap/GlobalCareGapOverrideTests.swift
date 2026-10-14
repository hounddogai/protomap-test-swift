@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapOverrideTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGlobalCareGapOverride("code-681", name: "name-36")
        #expect(item.status == CareManagement.GlobalCareGapOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGlobalCareGapOverride("code-681", name: "name-36")
        try item.moveTo(CareManagement.GlobalCareGapOverrideStatus.reopened)
        #expect(item.status == CareManagement.GlobalCareGapOverrideStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGlobalCareGapOverride("code-681", name: "name-36")
        item.status = CareManagement.GlobalCareGapOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalCareGapOverrideStatus.`open`) }
    }
}

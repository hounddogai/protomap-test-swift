@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBundleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapBundle("code-300", label: "label-140")
        #expect(item.status == CareManagement.CareGapBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newCareGapBundle("code-300", label: "label-140")
        try item.moveTo(CareManagement.CareGapBundleStatus.inReview)
        #expect(item.status == CareManagement.CareGapBundleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapBundle("code-300", label: "label-140")
        item.status = CareManagement.CareGapBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapBundleStatus.`open`) }
    }
}

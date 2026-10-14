@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapGroupTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        #expect(item.status == CareManagement.PrimaryCareGapGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        try item.moveTo(CareManagement.PrimaryCareGapGroupStatus.validated)
        #expect(item.status == CareManagement.PrimaryCareGapGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        item.status = CareManagement.PrimaryCareGapGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryCareGapGroupStatus.created) }
    }
}

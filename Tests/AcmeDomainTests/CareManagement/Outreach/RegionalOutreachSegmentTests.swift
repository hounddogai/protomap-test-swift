@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachSegmentTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRegionalOutreachSegment("code-898", title: "title-343")
        #expect(item.status == CareManagement.RegionalOutreachSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newRegionalOutreachSegment("code-898", title: "title-343")
        try item.moveTo(CareManagement.RegionalOutreachSegmentStatus.validated)
        #expect(item.status == CareManagement.RegionalOutreachSegmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRegionalOutreachSegment("code-898", title: "title-343")
        item.status = CareManagement.RegionalOutreachSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalOutreachSegmentStatus.created) }
    }
}

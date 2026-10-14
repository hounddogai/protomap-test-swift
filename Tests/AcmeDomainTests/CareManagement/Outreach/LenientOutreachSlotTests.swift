@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachSlotTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newLenientOutreachSlot("code-853", title: "title-186")
        #expect(item.status == CareManagement.LenientOutreachSlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newLenientOutreachSlot("code-853", title: "title-186")
        try item.moveTo(CareManagement.LenientOutreachSlotStatus.inReview)
        #expect(item.status == CareManagement.LenientOutreachSlotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newLenientOutreachSlot("code-853", title: "title-186")
        item.status = CareManagement.LenientOutreachSlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachSlotStatus.`open`) }
    }
}

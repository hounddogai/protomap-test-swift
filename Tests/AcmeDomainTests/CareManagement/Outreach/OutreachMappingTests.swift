@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachMappingTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newOutreachMapping("code-74", title: "title-403")
        #expect(item.status == CareManagement.OutreachMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newOutreachMapping("code-74", title: "title-403")
        try item.moveTo(CareManagement.OutreachMappingStatus.inProgress)
        #expect(item.status == CareManagement.OutreachMappingStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newOutreachMapping("code-74", title: "title-403")
        item.status = CareManagement.OutreachMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachMappingStatus.planned) }
    }
}

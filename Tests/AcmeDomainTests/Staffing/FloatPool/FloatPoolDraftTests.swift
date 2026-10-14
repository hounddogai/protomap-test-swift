@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolDraftTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFloatPoolDraft("code-759", name: "name-584")
        #expect(item.status == Staffing.FloatPoolDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newFloatPoolDraft("code-759", name: "name-584")
        try item.moveTo(Staffing.FloatPoolDraftStatus.archived)
        #expect(item.status == Staffing.FloatPoolDraftStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFloatPoolDraft("code-759", name: "name-584")
        item.status = Staffing.FloatPoolDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolDraftStatus.`open`) }
    }
}

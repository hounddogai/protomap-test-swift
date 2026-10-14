@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramProfileTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newLenientProgramProfile("code-414", title: "title-554")
        #expect(item.status == CareManagement.LenientProgramProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newLenientProgramProfile("code-414", title: "title-554")
        try item.moveTo(CareManagement.LenientProgramProfileStatus.queued)
        #expect(item.status == CareManagement.LenientProgramProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newLenientProgramProfile("code-414", title: "title-554")
        item.status = CareManagement.LenientProgramProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientProgramProfileStatus.new) }
    }
}

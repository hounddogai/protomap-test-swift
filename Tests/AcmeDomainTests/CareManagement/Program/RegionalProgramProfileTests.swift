@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalProgramProfileTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRegionalProgramProfile("code-625", name: "name-525")
        #expect(item.status == CareManagement.RegionalProgramProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newRegionalProgramProfile("code-625", name: "name-525")
        try item.moveTo(CareManagement.RegionalProgramProfileStatus.done)
        #expect(item.status == CareManagement.RegionalProgramProfileStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRegionalProgramProfile("code-625", name: "name-525")
        item.status = CareManagement.RegionalProgramProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalProgramProfileStatus.new) }
    }
}

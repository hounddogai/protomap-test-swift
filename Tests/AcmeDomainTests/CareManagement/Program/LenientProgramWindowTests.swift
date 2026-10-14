@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramWindowTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newLenientProgramWindow("code-584", name: "name-192")
        #expect(item.status == CareManagement.LenientProgramWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newLenientProgramWindow("code-584", name: "name-192")
        try item.moveTo(CareManagement.LenientProgramWindowStatus.rejected)
        #expect(item.status == CareManagement.LenientProgramWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newLenientProgramWindow("code-584", name: "name-192")
        item.status = CareManagement.LenientProgramWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientProgramWindowStatus.proposed) }
    }
}

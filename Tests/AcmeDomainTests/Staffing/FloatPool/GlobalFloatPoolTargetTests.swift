@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolTargetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newGlobalFloatPoolTarget("code-262", name: "name-359")
        #expect(item.status == Staffing.GlobalFloatPoolTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newGlobalFloatPoolTarget("code-262", name: "name-359")
        try item.moveTo(Staffing.GlobalFloatPoolTargetStatus.rejected)
        #expect(item.status == Staffing.GlobalFloatPoolTargetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newGlobalFloatPoolTarget("code-262", name: "name-359")
        item.status = Staffing.GlobalFloatPoolTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalFloatPoolTargetStatus.proposed) }
    }
}

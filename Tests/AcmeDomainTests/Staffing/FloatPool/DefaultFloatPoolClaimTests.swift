@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolClaimTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newDefaultFloatPoolClaim("code-246", label: "label-750")
        #expect(item.status == Staffing.DefaultFloatPoolClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newDefaultFloatPoolClaim("code-246", label: "label-750")
        try item.moveTo(Staffing.DefaultFloatPoolClaimStatus.scheduled)
        #expect(item.status == Staffing.DefaultFloatPoolClaimStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newDefaultFloatPoolClaim("code-246", label: "label-750")
        item.status = Staffing.DefaultFloatPoolClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultFloatPoolClaimStatus.planned) }
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolClaimTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFloatPoolClaim("code-345", label: "label-865")
        #expect(item.status == Staffing.FloatPoolClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newFloatPoolClaim("code-345", label: "label-865")
        try item.moveTo(Staffing.FloatPoolClaimStatus.done)
        #expect(item.status == Staffing.FloatPoolClaimStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFloatPoolClaim("code-345", label: "label-865")
        item.status = Staffing.FloatPoolClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolClaimStatus.new) }
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolRequestTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newDefaultFloatPoolRequest("code-216", name: "name-919")
        #expect(item.status == Staffing.DefaultFloatPoolRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newDefaultFloatPoolRequest("code-216", name: "name-919")
        try item.moveTo(Staffing.DefaultFloatPoolRequestStatus.withdrawn)
        #expect(item.status == Staffing.DefaultFloatPoolRequestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newDefaultFloatPoolRequest("code-216", name: "name-919")
        item.status = Staffing.DefaultFloatPoolRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultFloatPoolRequestStatus.proposed) }
    }
}

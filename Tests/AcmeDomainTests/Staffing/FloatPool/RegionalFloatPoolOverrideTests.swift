@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRegionalFloatPoolOverride("code-321", title: "title-775")
        #expect(item.status == Staffing.RegionalFloatPoolOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newRegionalFloatPoolOverride("code-321", title: "title-775")
        try item.moveTo(Staffing.RegionalFloatPoolOverrideStatus.inProgress)
        #expect(item.status == Staffing.RegionalFloatPoolOverrideStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRegionalFloatPoolOverride("code-321", title: "title-775")
        item.status = Staffing.RegionalFloatPoolOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalFloatPoolOverrideStatus.planned) }
    }
}

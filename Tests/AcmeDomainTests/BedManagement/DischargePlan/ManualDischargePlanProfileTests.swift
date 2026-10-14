@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanProfileTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newManualDischargePlanProfile("code-948", title: "title-94")
        #expect(item.status == BedManagement.ManualDischargePlanProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newManualDischargePlanProfile("code-948", title: "title-94")
        try item.moveTo(BedManagement.ManualDischargePlanProfileStatus.completed)
        #expect(item.status == BedManagement.ManualDischargePlanProfileStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newManualDischargePlanProfile("code-948", title: "title-94")
        item.status = BedManagement.ManualDischargePlanProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualDischargePlanProfileStatus.planned) }
    }
}

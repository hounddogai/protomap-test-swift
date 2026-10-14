@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanWindowTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        #expect(item.status == BedManagement.LenientDischargePlanWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        try item.moveTo(BedManagement.LenientDischargePlanWindowStatus.retired)
        #expect(item.status == BedManagement.LenientDischargePlanWindowStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        item.status = BedManagement.LenientDischargePlanWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientDischargePlanWindowStatus.created) }
    }
}

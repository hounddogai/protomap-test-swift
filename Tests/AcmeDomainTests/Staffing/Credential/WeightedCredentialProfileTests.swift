@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialProfileTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newWeightedCredentialProfile("code-919", name: "name-364")
        #expect(item.status == Staffing.WeightedCredentialProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newWeightedCredentialProfile("code-919", name: "name-364")
        try item.moveTo(Staffing.WeightedCredentialProfileStatus.granted)
        #expect(item.status == Staffing.WeightedCredentialProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newWeightedCredentialProfile("code-919", name: "name-364")
        item.status = Staffing.WeightedCredentialProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedCredentialProfileStatus.requested) }
    }
}

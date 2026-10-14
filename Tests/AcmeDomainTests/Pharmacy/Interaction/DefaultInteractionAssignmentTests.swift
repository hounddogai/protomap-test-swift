@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDefaultInteractionAssignment("code-804", name: "name-828")
        #expect(item.status == Pharmacy.DefaultInteractionAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newDefaultInteractionAssignment("code-804", name: "name-828")
        try item.moveTo(Pharmacy.DefaultInteractionAssignmentStatus.draining)
        #expect(item.status == Pharmacy.DefaultInteractionAssignmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDefaultInteractionAssignment("code-804", name: "name-828")
        item.status = Pharmacy.DefaultInteractionAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionAssignmentStatus.idle) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallGroupTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newManualRecallGroup("code-230", name: "name-961")
        #expect(item.status == Pharmacy.ManualRecallGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newManualRecallGroup("code-230", name: "name-961")
        try item.moveTo(Pharmacy.ManualRecallGroupStatus.ready)
        #expect(item.status == Pharmacy.ManualRecallGroupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newManualRecallGroup("code-230", name: "name-961")
        item.status = Pharmacy.ManualRecallGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallGroupStatus.idle) }
    }
}

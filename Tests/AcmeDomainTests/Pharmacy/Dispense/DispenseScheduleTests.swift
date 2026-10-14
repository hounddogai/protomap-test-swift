@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseScheduleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseSchedule("code-380", label: "label-664")
        #expect(item.status == Pharmacy.DispenseScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newDispenseSchedule("code-380", label: "label-664")
        try item.moveTo(Pharmacy.DispenseScheduleStatus.granted)
        #expect(item.status == Pharmacy.DispenseScheduleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseSchedule("code-380", label: "label-664")
        item.status = Pharmacy.DispenseScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseScheduleStatus.requested) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallNoticeTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newManualRecallNotice("code-391", label: "label-700")
        #expect(item.status == Pharmacy.ManualRecallNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newManualRecallNotice("code-391", label: "label-700")
        try item.moveTo(Pharmacy.ManualRecallNoticeStatus.granted)
        #expect(item.status == Pharmacy.ManualRecallNoticeStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newManualRecallNotice("code-391", label: "label-700")
        item.status = Pharmacy.ManualRecallNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallNoticeStatus.requested) }
    }
}

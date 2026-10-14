@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newDispenseNotice("code-691", title: "title-852")
        #expect(item.status == Pharmacy.DispenseNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newDispenseNotice("code-691", title: "title-852")
        try item.moveTo(Pharmacy.DispenseNoticeStatus.cancelled)
        #expect(item.status == Pharmacy.DispenseNoticeStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newDispenseNotice("code-691", title: "title-852")
        item.status = Pharmacy.DispenseNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseNoticeStatus.planned) }
    }
}

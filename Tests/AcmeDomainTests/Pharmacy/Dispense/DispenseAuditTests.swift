@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAuditTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispenseAudit("code-790", title: "title-429")
        #expect(item.status == Pharmacy.DispenseAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDispenseAudit("code-790", title: "title-429")
        try item.moveTo(Pharmacy.DispenseAuditStatus.warming)
        #expect(item.status == Pharmacy.DispenseAuditStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispenseAudit("code-790", title: "title-429")
        item.status = Pharmacy.DispenseAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseAuditStatus.idle) }
    }
}

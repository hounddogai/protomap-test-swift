@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseTemplateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newPendingDispenseTemplate("code-541", title: "title-662")
        #expect(item.status == Pharmacy.PendingDispenseTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newPendingDispenseTemplate("code-541", title: "title-662")
        try item.moveTo(Pharmacy.PendingDispenseTemplateStatus.ready)
        #expect(item.status == Pharmacy.PendingDispenseTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newPendingDispenseTemplate("code-541", title: "title-662")
        item.status = Pharmacy.PendingDispenseTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingDispenseTemplateStatus.idle) }
    }
}

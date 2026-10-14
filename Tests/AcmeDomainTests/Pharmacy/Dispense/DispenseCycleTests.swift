@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseCycleTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        #expect(item.status == Pharmacy.DispenseCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        try item.moveTo(Pharmacy.DispenseCycleStatus.running)
        #expect(item.status == Pharmacy.DispenseCycleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        item.status = Pharmacy.DispenseCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseCycleStatus.new) }
    }
}

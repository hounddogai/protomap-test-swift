@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispensePlanTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispensePlan("code-465", title: "title-450")
        #expect(item.status == Pharmacy.DispensePlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newDispensePlan("code-465", title: "title-450")
        try item.moveTo(Pharmacy.DispensePlanStatus.ready)
        #expect(item.status == Pharmacy.DispensePlanStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispensePlan("code-465", title: "title-450")
        item.status = Pharmacy.DispensePlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispensePlanStatus.idle) }
    }
}

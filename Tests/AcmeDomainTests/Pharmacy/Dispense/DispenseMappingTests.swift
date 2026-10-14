@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseMappingTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newDispenseMapping("code-231", name: "name-903")
        #expect(item.status == Pharmacy.DispenseMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newDispenseMapping("code-231", name: "name-903")
        try item.moveTo(Pharmacy.DispenseMappingStatus.running)
        #expect(item.status == Pharmacy.DispenseMappingStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newDispenseMapping("code-231", name: "name-903")
        item.status = Pharmacy.DispenseMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseMappingStatus.new) }
    }
}

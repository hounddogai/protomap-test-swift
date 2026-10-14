@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTierTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newDispenseTier("code-940", name: "name-413")
        #expect(item.status == Pharmacy.DispenseTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Pharmacy.newDispenseTier("code-940", name: "name-413")
        try item.moveTo(Pharmacy.DispenseTierStatus.archived)
        #expect(item.status == Pharmacy.DispenseTierStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newDispenseTier("code-940", name: "name-413")
        item.status = Pharmacy.DispenseTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseTierStatus.`open`) }
    }
}

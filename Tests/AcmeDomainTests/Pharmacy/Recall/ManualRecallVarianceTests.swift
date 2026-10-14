@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallVarianceTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newManualRecallVariance("code-424", name: "name-760")
        #expect(item.status == Pharmacy.ManualRecallVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newManualRecallVariance("code-424", name: "name-760")
        try item.moveTo(Pharmacy.ManualRecallVarianceStatus.published)
        #expect(item.status == Pharmacy.ManualRecallVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newManualRecallVariance("code-424", name: "name-760")
        item.status = Pharmacy.ManualRecallVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallVarianceStatus.created) }
    }
}

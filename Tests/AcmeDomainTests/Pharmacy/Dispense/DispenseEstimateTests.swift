@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEstimateTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseEstimate("code-321", title: "title-748")
        #expect(item.status == Pharmacy.DispenseEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newDispenseEstimate("code-321", title: "title-748")
        try item.moveTo(Pharmacy.DispenseEstimateStatus.expired)
        #expect(item.status == Pharmacy.DispenseEstimateStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseEstimate("code-321", title: "title-748")
        item.status = Pharmacy.DispenseEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseEstimateStatus.requested) }
    }
}

@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyDigestTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newAdaptiveFormularyDigest("code-596", label: "label-839")
        #expect(item.status == Pharmacy.AdaptiveFormularyDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newAdaptiveFormularyDigest("code-596", label: "label-839")
        try item.moveTo(Pharmacy.AdaptiveFormularyDigestStatus.ready)
        #expect(item.status == Pharmacy.AdaptiveFormularyDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newAdaptiveFormularyDigest("code-596", label: "label-839")
        item.status = Pharmacy.AdaptiveFormularyDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveFormularyDigestStatus.idle) }
    }
}

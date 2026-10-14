@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyOverrideTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newAdaptiveFormularyOverride("code-274", label: "label-825")
        #expect(item.status == Pharmacy.AdaptiveFormularyOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newAdaptiveFormularyOverride("code-274", label: "label-825")
        try item.moveTo(Pharmacy.AdaptiveFormularyOverrideStatus.ready)
        #expect(item.status == Pharmacy.AdaptiveFormularyOverrideStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newAdaptiveFormularyOverride("code-274", label: "label-825")
        item.status = Pharmacy.AdaptiveFormularyOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveFormularyOverrideStatus.idle) }
    }
}

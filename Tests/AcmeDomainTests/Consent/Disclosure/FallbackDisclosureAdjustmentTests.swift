@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Consent.newFallbackDisclosureAdjustment("code-586", name: "name-417")
        #expect(item.status == Consent.FallbackDisclosureAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newFallbackDisclosureAdjustment("code-586", name: "name-417")
        try item.moveTo(Consent.FallbackDisclosureAdjustmentStatus.validated)
        #expect(item.status == Consent.FallbackDisclosureAdjustmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newFallbackDisclosureAdjustment("code-586", name: "name-417")
        item.status = Consent.FallbackDisclosureAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackDisclosureAdjustmentStatus.created) }
    }
}

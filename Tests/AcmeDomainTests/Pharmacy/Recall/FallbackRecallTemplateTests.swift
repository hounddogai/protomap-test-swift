@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallTemplateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFallbackRecallTemplate("code-152", name: "name-944")
        #expect(item.status == Pharmacy.FallbackRecallTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newFallbackRecallTemplate("code-152", name: "name-944")
        try item.moveTo(Pharmacy.FallbackRecallTemplateStatus.warming)
        #expect(item.status == Pharmacy.FallbackRecallTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFallbackRecallTemplate("code-152", name: "name-944")
        item.status = Pharmacy.FallbackRecallTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackRecallTemplateStatus.idle) }
    }
}

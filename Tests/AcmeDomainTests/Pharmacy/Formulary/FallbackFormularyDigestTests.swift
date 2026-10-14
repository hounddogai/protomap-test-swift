@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyDigestTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newFallbackFormularyDigest("code-147", name: "name-426")
        #expect(item.status == Pharmacy.FallbackFormularyDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Pharmacy.newFallbackFormularyDigest("code-147", name: "name-426")
        try item.moveTo(Pharmacy.FallbackFormularyDigestStatus.archived)
        #expect(item.status == Pharmacy.FallbackFormularyDigestStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newFallbackFormularyDigest("code-147", name: "name-426")
        item.status = Pharmacy.FallbackFormularyDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackFormularyDigestStatus.`open`) }
    }
}

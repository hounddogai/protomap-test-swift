@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionClaimTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionClaim("code-131", name: "name-296")
        #expect(item.status == Labs.AccessionClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newAccessionClaim("code-131", name: "name-296")
        try item.moveTo(Labs.AccessionClaimStatus.ready)
        #expect(item.status == Labs.AccessionClaimStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionClaim("code-131", name: "name-296")
        item.status = Labs.AccessionClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionClaimStatus.idle) }
    }
}

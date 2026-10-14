@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPolicyTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionPolicy("code-102", title: "title-454")
        #expect(item.status == Labs.AccessionPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newAccessionPolicy("code-102", title: "title-454")
        try item.moveTo(Labs.AccessionPolicyStatus.ready)
        #expect(item.status == Labs.AccessionPolicyStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionPolicy("code-102", title: "title-454")
        item.status = Labs.AccessionPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionPolicyStatus.idle) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenQuotaTests {
    @Test func startsInIdle() throws {
        let item = Labs.newDefaultSpecimenQuota("code-126", label: "label-174")
        #expect(item.status == Labs.DefaultSpecimenQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newDefaultSpecimenQuota("code-126", label: "label-174")
        try item.moveTo(Labs.DefaultSpecimenQuotaStatus.ready)
        #expect(item.status == Labs.DefaultSpecimenQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newDefaultSpecimenQuota("code-126", label: "label-174")
        item.status = Labs.DefaultSpecimenQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenQuotaStatus.idle) }
    }
}

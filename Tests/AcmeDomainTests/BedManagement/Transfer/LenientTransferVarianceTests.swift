@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferVarianceTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newLenientTransferVariance("code-141", title: "title-315")
        #expect(item.status == BedManagement.LenientTransferVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newLenientTransferVariance("code-141", title: "title-315")
        try item.moveTo(BedManagement.LenientTransferVarianceStatus.revoked)
        #expect(item.status == BedManagement.LenientTransferVarianceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newLenientTransferVariance("code-141", title: "title-315")
        item.status = BedManagement.LenientTransferVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientTransferVarianceStatus.requested) }
    }
}

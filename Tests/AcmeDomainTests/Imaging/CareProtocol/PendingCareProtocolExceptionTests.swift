@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingCareProtocolExceptionTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPendingCareProtocolException("code-663", name: "name-668")
        #expect(item.status == Imaging.PendingCareProtocolExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newPendingCareProtocolException("code-663", name: "name-668")
        try item.moveTo(Imaging.PendingCareProtocolExceptionStatus.approved)
        #expect(item.status == Imaging.PendingCareProtocolExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPendingCareProtocolException("code-663", name: "name-668")
        item.status = Imaging.PendingCareProtocolExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingCareProtocolExceptionStatus.proposed) }
    }
}

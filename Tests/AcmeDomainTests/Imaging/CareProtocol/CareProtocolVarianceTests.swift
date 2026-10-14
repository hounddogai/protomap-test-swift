@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolVarianceTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newCareProtocolVariance("code-87", title: "title-694")
        #expect(item.status == Imaging.CareProtocolVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newCareProtocolVariance("code-87", title: "title-694")
        try item.moveTo(Imaging.CareProtocolVarianceStatus.rejected)
        #expect(item.status == Imaging.CareProtocolVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newCareProtocolVariance("code-87", title: "title-694")
        item.status = Imaging.CareProtocolVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolVarianceStatus.proposed) }
    }
}

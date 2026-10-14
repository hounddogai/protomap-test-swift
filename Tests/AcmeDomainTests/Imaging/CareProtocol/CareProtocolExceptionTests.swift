@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolExceptionTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolException("code-208", name: "name-627")
        #expect(item.status == Imaging.CareProtocolExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newCareProtocolException("code-208", name: "name-627")
        try item.moveTo(Imaging.CareProtocolExceptionStatus.done)
        #expect(item.status == Imaging.CareProtocolExceptionStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolException("code-208", name: "name-627")
        item.status = Imaging.CareProtocolExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolExceptionStatus.new) }
    }
}

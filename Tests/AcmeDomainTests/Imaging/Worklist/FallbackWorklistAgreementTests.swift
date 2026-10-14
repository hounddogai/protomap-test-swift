@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistAgreementTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newFallbackWorklistAgreement("code-273", title: "title-452")
        #expect(item.status == Imaging.FallbackWorklistAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newFallbackWorklistAgreement("code-273", title: "title-452")
        try item.moveTo(Imaging.FallbackWorklistAgreementStatus.stopped)
        #expect(item.status == Imaging.FallbackWorklistAgreementStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newFallbackWorklistAgreement("code-273", title: "title-452")
        item.status = Imaging.FallbackWorklistAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackWorklistAgreementStatus.idle) }
    }
}

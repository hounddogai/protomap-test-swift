@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationBundleTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRollingRevocationBundle("code-617", title: "title-175")
        #expect(item.status == Consent.RollingRevocationBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newRollingRevocationBundle("code-617", title: "title-175")
        try item.moveTo(Consent.RollingRevocationBundleStatus.stopped)
        #expect(item.status == Consent.RollingRevocationBundleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRollingRevocationBundle("code-617", title: "title-175")
        item.status = Consent.RollingRevocationBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingRevocationBundleStatus.idle) }
    }
}

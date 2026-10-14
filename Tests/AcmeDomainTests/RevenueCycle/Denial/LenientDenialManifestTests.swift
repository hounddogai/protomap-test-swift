@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialManifestTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLenientDenialManifest("code-106", label: "label-199")
        #expect(item.status == RevenueCycle.LenientDenialManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newLenientDenialManifest("code-106", label: "label-199")
        try item.moveTo(RevenueCycle.LenientDenialManifestStatus.validated)
        #expect(item.status == RevenueCycle.LenientDenialManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLenientDenialManifest("code-106", label: "label-199")
        item.status = RevenueCycle.LenientDenialManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientDenialManifestStatus.created) }
    }
}

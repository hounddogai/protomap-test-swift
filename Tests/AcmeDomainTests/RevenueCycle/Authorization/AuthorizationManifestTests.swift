@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationManifestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationManifest("code-459", label: "label-412")
        #expect(item.status == RevenueCycle.AuthorizationManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newAuthorizationManifest("code-459", label: "label-412")
        try item.moveTo(RevenueCycle.AuthorizationManifestStatus.reopened)
        #expect(item.status == RevenueCycle.AuthorizationManifestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationManifest("code-459", label: "label-412")
        item.status = RevenueCycle.AuthorizationManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationManifestStatus.`open`) }
    }
}

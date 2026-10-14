@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialManifestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newDenialManifest("code-680", name: "name-175")
        #expect(item.status == RevenueCycle.DenialManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newDenialManifest("code-680", name: "name-175")
        try item.moveTo(RevenueCycle.DenialManifestStatus.resolved)
        #expect(item.status == RevenueCycle.DenialManifestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newDenialManifest("code-680", name: "name-175")
        item.status = RevenueCycle.DenialManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialManifestStatus.`open`) }
    }
}

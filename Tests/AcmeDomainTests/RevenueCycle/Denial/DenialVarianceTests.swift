@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialVarianceTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDenialVariance("code-693", title: "title-563")
        #expect(item.status == RevenueCycle.DenialVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newDenialVariance("code-693", title: "title-563")
        try item.moveTo(RevenueCycle.DenialVarianceStatus.queued)
        #expect(item.status == RevenueCycle.DenialVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDenialVariance("code-693", title: "title-563")
        item.status = RevenueCycle.DenialVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialVarianceStatus.new) }
    }
}

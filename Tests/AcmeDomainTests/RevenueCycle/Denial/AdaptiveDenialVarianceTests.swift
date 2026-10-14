@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveDenialVarianceTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAdaptiveDenialVariance("code-915", label: "label-640")
        #expect(item.status == RevenueCycle.AdaptiveDenialVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newAdaptiveDenialVariance("code-915", label: "label-640")
        try item.moveTo(RevenueCycle.AdaptiveDenialVarianceStatus.done)
        #expect(item.status == RevenueCycle.AdaptiveDenialVarianceStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAdaptiveDenialVariance("code-915", label: "label-640")
        item.status = RevenueCycle.AdaptiveDenialVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveDenialVarianceStatus.new) }
    }
}

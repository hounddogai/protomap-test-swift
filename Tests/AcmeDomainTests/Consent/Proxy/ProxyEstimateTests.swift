@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEstimateTests {
    @Test func startsInNew() throws {
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        #expect(item.status == Consent.ProxyEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        try item.moveTo(Consent.ProxyEstimateStatus.failed)
        #expect(item.status == Consent.ProxyEstimateStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        item.status = Consent.ProxyEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyEstimateStatus.new) }
    }
}

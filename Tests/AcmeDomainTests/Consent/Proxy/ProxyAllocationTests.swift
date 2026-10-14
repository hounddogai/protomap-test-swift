@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAllocationTests {
    @Test func startsInNew() throws {
        let item = Consent.newProxyAllocation("code-92", name: "name-649")
        #expect(item.status == Consent.ProxyAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newProxyAllocation("code-92", name: "name-649")
        try item.moveTo(Consent.ProxyAllocationStatus.running)
        #expect(item.status == Consent.ProxyAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newProxyAllocation("code-92", name: "name-649")
        item.status = Consent.ProxyAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyAllocationStatus.new) }
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceVarianceTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRegionalRemittanceVariance("code-285", name: "name-892")
        #expect(item.status == RevenueCycle.RegionalRemittanceVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRegionalRemittanceVariance("code-285", name: "name-892")
        try item.moveTo(RevenueCycle.RegionalRemittanceVarianceStatus.validated)
        #expect(item.status == RevenueCycle.RegionalRemittanceVarianceStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRegionalRemittanceVariance("code-285", name: "name-892")
        item.status = RevenueCycle.RegionalRemittanceVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalRemittanceVarianceStatus.created) }
    }
}

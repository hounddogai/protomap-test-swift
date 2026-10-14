@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceVarianceTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newRemittanceVariance("code-20", name: "name-830")
        #expect(item.status == RevenueCycle.RemittanceVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newRemittanceVariance("code-20", name: "name-830")
        try item.moveTo(RevenueCycle.RemittanceVarianceStatus.resolved)
        #expect(item.status == RevenueCycle.RemittanceVarianceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newRemittanceVariance("code-20", name: "name-830")
        item.status = RevenueCycle.RemittanceVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceVarianceStatus.`open`) }
    }
}

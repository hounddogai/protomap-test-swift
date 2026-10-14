@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceExceptionTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newRemittanceException("code-872", name: "name-351")
        #expect(item.status == RevenueCycle.RemittanceExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newRemittanceException("code-872", name: "name-351")
        try item.moveTo(RevenueCycle.RemittanceExceptionStatus.inReview)
        #expect(item.status == RevenueCycle.RemittanceExceptionStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newRemittanceException("code-872", name: "name-351")
        item.status = RevenueCycle.RemittanceExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceExceptionStatus.`open`) }
    }
}

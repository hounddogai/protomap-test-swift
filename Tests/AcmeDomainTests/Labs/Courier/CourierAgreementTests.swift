@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAgreementTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierAgreement("code-460", name: "name-492")
        #expect(item.status == Labs.CourierAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newCourierAgreement("code-460", name: "name-492")
        try item.moveTo(Labs.CourierAgreementStatus.approved)
        #expect(item.status == Labs.CourierAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierAgreement("code-460", name: "name-492")
        item.status = Labs.CourierAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierAgreementStatus.proposed) }
    }
}

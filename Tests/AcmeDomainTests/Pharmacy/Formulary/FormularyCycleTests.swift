@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCycleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularyCycle("code-252", title: "title-94")
        #expect(item.status == Pharmacy.FormularyCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newFormularyCycle("code-252", title: "title-94")
        try item.moveTo(Pharmacy.FormularyCycleStatus.validated)
        #expect(item.status == Pharmacy.FormularyCycleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularyCycle("code-252", title: "title-94")
        item.status = Pharmacy.FormularyCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyCycleStatus.created) }
    }
}

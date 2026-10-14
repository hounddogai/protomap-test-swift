@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureAllocation("code-651", label: "label-772")
        #expect(item.status == Consent.DisclosureAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newDisclosureAllocation("code-651", label: "label-772")
        try item.moveTo(Consent.DisclosureAllocationStatus.inProgress)
        #expect(item.status == Consent.DisclosureAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureAllocation("code-651", label: "label-772")
        item.status = Consent.DisclosureAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureAllocationStatus.planned) }
    }
}

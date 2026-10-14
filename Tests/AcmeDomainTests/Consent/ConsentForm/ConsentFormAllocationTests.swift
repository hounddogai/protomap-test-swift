@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAllocationTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormAllocation("code-69", title: "title-886")
        #expect(item.status == Consent.ConsentFormAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newConsentFormAllocation("code-69", title: "title-886")
        try item.moveTo(Consent.ConsentFormAllocationStatus.granted)
        #expect(item.status == Consent.ConsentFormAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormAllocation("code-69", title: "title-886")
        item.status = Consent.ConsentFormAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormAllocationStatus.requested) }
    }
}

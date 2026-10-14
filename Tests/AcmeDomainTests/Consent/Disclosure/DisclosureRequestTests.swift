@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRequestTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDisclosureRequest("code-870", label: "label-641")
        #expect(item.status == Consent.DisclosureRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newDisclosureRequest("code-870", label: "label-641")
        try item.moveTo(Consent.DisclosureRequestStatus.warming)
        #expect(item.status == Consent.DisclosureRequestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDisclosureRequest("code-870", label: "label-641")
        item.status = Consent.DisclosureRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureRequestStatus.idle) }
    }
}

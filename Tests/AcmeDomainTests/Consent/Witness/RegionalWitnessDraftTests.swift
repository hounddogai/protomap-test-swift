@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalWitnessDraftTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRegionalWitnessDraft("code-637", label: "label-171")
        #expect(item.status == Consent.RegionalWitnessDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newRegionalWitnessDraft("code-637", label: "label-171")
        try item.moveTo(Consent.RegionalWitnessDraftStatus.expired)
        #expect(item.status == Consent.RegionalWitnessDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRegionalWitnessDraft("code-637", label: "label-171")
        item.status = Consent.RegionalWitnessDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalWitnessDraftStatus.requested) }
    }
}

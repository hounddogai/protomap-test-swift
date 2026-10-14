@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessTierTests {
    @Test func startsInNew() throws {
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        #expect(item.status == Consent.ManualWitnessTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        try item.moveTo(Consent.ManualWitnessTierStatus.done)
        #expect(item.status == Consent.ManualWitnessTierStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        item.status = Consent.ManualWitnessTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualWitnessTierStatus.new) }
    }
}

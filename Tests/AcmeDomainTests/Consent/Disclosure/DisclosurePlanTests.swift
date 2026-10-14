@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosurePlanTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDisclosurePlan("code-756", title: "title-919")
        #expect(item.status == Consent.DisclosurePlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newDisclosurePlan("code-756", title: "title-919")
        try item.moveTo(Consent.DisclosurePlanStatus.warming)
        #expect(item.status == Consent.DisclosurePlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDisclosurePlan("code-756", title: "title-919")
        item.status = Consent.DisclosurePlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosurePlanStatus.idle) }
    }
}

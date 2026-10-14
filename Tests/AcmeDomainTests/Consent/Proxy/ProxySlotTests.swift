@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxySlotTests {
    @Test func startsInProposed() throws {
        let item = Consent.newProxySlot("code-761", label: "label-787")
        #expect(item.status == Consent.ProxySlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newProxySlot("code-761", label: "label-787")
        try item.moveTo(Consent.ProxySlotStatus.rejected)
        #expect(item.status == Consent.ProxySlotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newProxySlot("code-761", label: "label-787")
        item.status = Consent.ProxySlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxySlotStatus.proposed) }
    }
}

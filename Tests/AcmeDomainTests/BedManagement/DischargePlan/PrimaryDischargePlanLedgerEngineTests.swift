@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryDischargePlanLedgerEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newPrimaryDischargePlanLedger("code-503", title: "title-922")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

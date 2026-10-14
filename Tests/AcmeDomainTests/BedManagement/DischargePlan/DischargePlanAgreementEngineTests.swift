@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDischargePlanAgreementEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newDischargePlanAgreement("code-948", label: "label-888")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultStrictOvertimeAgreementEngine()
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

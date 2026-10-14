@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultDefaultCredentialWindowEngine(Kit.Flags.newRegistry())
        let item = Staffing.newDefaultCredentialWindow("code-534", label: "label-989")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

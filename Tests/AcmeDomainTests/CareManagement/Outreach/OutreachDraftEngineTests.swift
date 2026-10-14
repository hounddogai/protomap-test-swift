@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultOutreachDraftEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newOutreachDraft("code-153", title: "title-281")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

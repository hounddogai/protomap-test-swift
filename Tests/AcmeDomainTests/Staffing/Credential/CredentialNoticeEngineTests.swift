@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCredentialNoticeEngine()
        let item = Staffing.newCredentialNotice("code-747", title: "title-690")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialTemplateTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newAdaptiveCredentialTemplate("code-227", name: "name-789")
        #expect(item.status == Staffing.AdaptiveCredentialTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newAdaptiveCredentialTemplate("code-227", name: "name-789")
        try item.moveTo(Staffing.AdaptiveCredentialTemplateStatus.ready)
        #expect(item.status == Staffing.AdaptiveCredentialTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newAdaptiveCredentialTemplate("code-227", name: "name-789")
        item.status = Staffing.AdaptiveCredentialTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveCredentialTemplateStatus.idle) }
    }
}

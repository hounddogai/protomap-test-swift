@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanManifestTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newAcuityPlanManifest("code-358", name: "name-723")
        #expect(item.status == Staffing.AcuityPlanManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newAcuityPlanManifest("code-358", name: "name-723")
        try item.moveTo(Staffing.AcuityPlanManifestStatus.warming)
        #expect(item.status == Staffing.AcuityPlanManifestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newAcuityPlanManifest("code-358", name: "name-723")
        item.status = Staffing.AcuityPlanManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanManifestStatus.idle) }
    }
}

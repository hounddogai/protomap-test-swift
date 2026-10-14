@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeManifestTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newStrictOvertimeManifest("code-323", name: "name-841")
        #expect(item.status == Staffing.StrictOvertimeManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newStrictOvertimeManifest("code-323", name: "name-841")
        try item.moveTo(Staffing.StrictOvertimeManifestStatus.ready)
        #expect(item.status == Staffing.StrictOvertimeManifestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newStrictOvertimeManifest("code-323", name: "name-841")
        item.status = Staffing.StrictOvertimeManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictOvertimeManifestStatus.idle) }
    }
}

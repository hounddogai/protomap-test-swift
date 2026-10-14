@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftMappingTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFallbackShiftMapping("code-594", name: "name-982")
        #expect(item.status == Staffing.FallbackShiftMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newFallbackShiftMapping("code-594", name: "name-982")
        try item.moveTo(Staffing.FallbackShiftMappingStatus.warming)
        #expect(item.status == Staffing.FallbackShiftMappingStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFallbackShiftMapping("code-594", name: "name-982")
        item.status = Staffing.FallbackShiftMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackShiftMappingStatus.idle) }
    }
}

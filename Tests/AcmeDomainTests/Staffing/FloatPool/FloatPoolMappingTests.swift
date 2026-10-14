@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMappingTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolMapping("code-264", title: "title-936")
        #expect(item.status == Staffing.FloatPoolMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newFloatPoolMapping("code-264", title: "title-936")
        try item.moveTo(Staffing.FloatPoolMappingStatus.withdrawn)
        #expect(item.status == Staffing.FloatPoolMappingStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolMapping("code-264", title: "title-936")
        item.status = Staffing.FloatPoolMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolMappingStatus.proposed) }
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalFloatPoolTemplateTests {
    @Test func startsInNew() throws {
        let item = Staffing.newSeasonalFloatPoolTemplate("code-119", label: "label-647")
        #expect(item.status == Staffing.SeasonalFloatPoolTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newSeasonalFloatPoolTemplate("code-119", label: "label-647")
        try item.moveTo(Staffing.SeasonalFloatPoolTemplateStatus.failed)
        #expect(item.status == Staffing.SeasonalFloatPoolTemplateStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newSeasonalFloatPoolTemplate("code-119", label: "label-647")
        item.status = Staffing.SeasonalFloatPoolTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalFloatPoolTemplateStatus.new) }
    }
}

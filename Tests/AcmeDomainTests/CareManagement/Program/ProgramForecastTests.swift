@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramForecastTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newProgramForecast("code-446", title: "title-606")
        #expect(item.status == CareManagement.ProgramForecastStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newProgramForecast("code-446", title: "title-606")
        try item.moveTo(CareManagement.ProgramForecastStatus.running)
        #expect(item.status == CareManagement.ProgramForecastStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newProgramForecast("code-446", title: "title-606")
        item.status = CareManagement.ProgramForecastStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramForecastStatus.new) }
    }
}

@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolVarianceTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newRegionalFloatPoolVariance("code-444", title: "title-9")
        #expect(item.status == Staffing.RegionalFloatPoolVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newRegionalFloatPoolVariance("code-444", title: "title-9")
        try item.moveTo(Staffing.RegionalFloatPoolVarianceStatus.archived)
        #expect(item.status == Staffing.RegionalFloatPoolVarianceStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newRegionalFloatPoolVariance("code-444", title: "title-9")
        item.status = Staffing.RegionalFloatPoolVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalFloatPoolVarianceStatus.`open`) }
    }
}

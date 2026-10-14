@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusTemplateTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newStrictCensusTemplate("code-139", title: "title-951")
        #expect(item.status == BedManagement.StrictCensusTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newStrictCensusTemplate("code-139", title: "title-951")
        try item.moveTo(BedManagement.StrictCensusTemplateStatus.draining)
        #expect(item.status == BedManagement.StrictCensusTemplateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newStrictCensusTemplate("code-139", title: "title-951")
        item.status = BedManagement.StrictCensusTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictCensusTemplateStatus.idle) }
    }
}

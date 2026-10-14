@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCensusNoticeEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCensusNotice("code-856", title: "title-509")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

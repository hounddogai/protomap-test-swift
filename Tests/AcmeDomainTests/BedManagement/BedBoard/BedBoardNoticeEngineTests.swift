@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBedBoardNoticeEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBedBoardNotice("code-942", title: "title-424")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

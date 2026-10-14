@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardVarianceTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newDefaultBedBoardVariance("code-121", label: "label-81")
        #expect(item.status == BedManagement.DefaultBedBoardVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newDefaultBedBoardVariance("code-121", label: "label-81")
        try item.moveTo(BedManagement.DefaultBedBoardVarianceStatus.queued)
        #expect(item.status == BedManagement.DefaultBedBoardVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newDefaultBedBoardVariance("code-121", label: "label-81")
        item.status = BedManagement.DefaultBedBoardVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultBedBoardVarianceStatus.new) }
    }
}

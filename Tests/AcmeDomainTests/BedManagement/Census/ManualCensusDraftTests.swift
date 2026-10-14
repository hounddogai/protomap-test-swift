@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusDraftTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newManualCensusDraft("code-948", label: "label-111")
        #expect(item.status == BedManagement.ManualCensusDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newManualCensusDraft("code-948", label: "label-111")
        try item.moveTo(BedManagement.ManualCensusDraftStatus.validated)
        #expect(item.status == BedManagement.ManualCensusDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newManualCensusDraft("code-948", label: "label-111")
        item.status = BedManagement.ManualCensusDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCensusDraftStatus.created) }
    }
}

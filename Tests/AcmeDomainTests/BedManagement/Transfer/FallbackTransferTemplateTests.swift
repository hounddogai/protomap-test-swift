@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferTemplateTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newFallbackTransferTemplate("code-243", title: "title-263")
        #expect(item.status == BedManagement.FallbackTransferTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newFallbackTransferTemplate("code-243", title: "title-263")
        try item.moveTo(BedManagement.FallbackTransferTemplateStatus.warming)
        #expect(item.status == BedManagement.FallbackTransferTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newFallbackTransferTemplate("code-243", title: "title-263")
        item.status = BedManagement.FallbackTransferTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackTransferTemplateStatus.idle) }
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramExceptionTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAdaptiveProgramException("code-704", title: "title-871")
        #expect(item.status == CareManagement.AdaptiveProgramExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newAdaptiveProgramException("code-704", title: "title-871")
        try item.moveTo(CareManagement.AdaptiveProgramExceptionStatus.warming)
        #expect(item.status == CareManagement.AdaptiveProgramExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAdaptiveProgramException("code-704", title: "title-871")
        item.status = CareManagement.AdaptiveProgramExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveProgramExceptionStatus.idle) }
    }
}

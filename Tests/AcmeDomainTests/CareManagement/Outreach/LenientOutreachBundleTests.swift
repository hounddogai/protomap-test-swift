@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachBundleTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newLenientOutreachBundle("code-20", name: "name-716")
        #expect(item.status == CareManagement.LenientOutreachBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newLenientOutreachBundle("code-20", name: "name-716")
        try item.moveTo(CareManagement.LenientOutreachBundleStatus.ready)
        #expect(item.status == CareManagement.LenientOutreachBundleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newLenientOutreachBundle("code-20", name: "name-716")
        item.status = CareManagement.LenientOutreachBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachBundleStatus.idle) }
    }
}

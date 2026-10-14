@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachRuleTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newLenientOutreachRule("code-686", name: "name-488")
        #expect(item.status == CareManagement.LenientOutreachRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newLenientOutreachRule("code-686", name: "name-488")
        try item.moveTo(CareManagement.LenientOutreachRuleStatus.warming)
        #expect(item.status == CareManagement.LenientOutreachRuleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newLenientOutreachRule("code-686", name: "name-488")
        item.status = CareManagement.LenientOutreachRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachRuleStatus.idle) }
    }
}

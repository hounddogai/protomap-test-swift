@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPreferenceTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachPreference("code-925", title: "title-13")
        #expect(item.status == CareManagement.OutreachPreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newOutreachPreference("code-925", title: "title-13")
        try item.moveTo(CareManagement.OutreachPreferenceStatus.failed)
        #expect(item.status == CareManagement.OutreachPreferenceStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachPreference("code-925", title: "title-13")
        item.status = CareManagement.OutreachPreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachPreferenceStatus.new) }
    }
}

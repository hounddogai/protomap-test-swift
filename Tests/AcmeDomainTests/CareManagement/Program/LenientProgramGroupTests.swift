@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramGroupTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newLenientProgramGroup("code-285", label: "label-405")
        #expect(item.status == CareManagement.LenientProgramGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newLenientProgramGroup("code-285", label: "label-405")
        try item.moveTo(CareManagement.LenientProgramGroupStatus.resolved)
        #expect(item.status == CareManagement.LenientProgramGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newLenientProgramGroup("code-285", label: "label-405")
        item.status = CareManagement.LenientProgramGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientProgramGroupStatus.`open`) }
    }
}

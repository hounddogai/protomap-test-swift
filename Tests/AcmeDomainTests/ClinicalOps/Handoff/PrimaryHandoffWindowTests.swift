@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffWindowTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPrimaryHandoffWindow("code-912", title: "title-8")
        #expect(item.status == ClinicalOps.PrimaryHandoffWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newPrimaryHandoffWindow("code-912", title: "title-8")
        try item.moveTo(ClinicalOps.PrimaryHandoffWindowStatus.granted)
        #expect(item.status == ClinicalOps.PrimaryHandoffWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPrimaryHandoffWindow("code-912", title: "title-8")
        item.status = ClinicalOps.PrimaryHandoffWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryHandoffWindowStatus.requested) }
    }
}

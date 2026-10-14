@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeBundleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPrimaryReferenceRangeBundle("code-205", label: "label-128")
        #expect(item.status == Labs.PrimaryReferenceRangeBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Labs.newPrimaryReferenceRangeBundle("code-205", label: "label-128")
        try item.moveTo(Labs.PrimaryReferenceRangeBundleStatus.archived)
        #expect(item.status == Labs.PrimaryReferenceRangeBundleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPrimaryReferenceRangeBundle("code-205", label: "label-128")
        item.status = Labs.PrimaryReferenceRangeBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryReferenceRangeBundleStatus.`open`) }
    }
}

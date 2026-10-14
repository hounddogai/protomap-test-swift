@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBundleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newAdaptiveSpecimenBundle("code-277", label: "label-879")
        #expect(item.status == Labs.AdaptiveSpecimenBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newAdaptiveSpecimenBundle("code-277", label: "label-879")
        try item.moveTo(Labs.AdaptiveSpecimenBundleStatus.resolved)
        #expect(item.status == Labs.AdaptiveSpecimenBundleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newAdaptiveSpecimenBundle("code-277", label: "label-879")
        item.status = Labs.AdaptiveSpecimenBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenBundleStatus.`open`) }
    }
}

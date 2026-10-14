@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenSummaryTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenSummary("code-153", name: "name-952")
        #expect(item.status == Labs.SpecimenSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newSpecimenSummary("code-153", name: "name-952")
        try item.moveTo(Labs.SpecimenSummaryStatus.failed)
        #expect(item.status == Labs.SpecimenSummaryStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenSummary("code-153", name: "name-952")
        item.status = Labs.SpecimenSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenSummaryStatus.new) }
    }
}

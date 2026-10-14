@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSummaryTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCourierSummary("code-488", name: "name-613")
        #expect(item.status == Labs.CourierSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCourierSummary("code-488", name: "name-613")
        try item.moveTo(Labs.CourierSummaryStatus.validated)
        #expect(item.status == Labs.CourierSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCourierSummary("code-488", name: "name-613")
        item.status = Labs.CourierSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierSummaryStatus.created) }
    }
}

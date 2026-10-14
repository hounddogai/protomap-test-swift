@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBundleTests {
    @Test func startsInProposed() throws {
        let item = Labs.newResultBundle("code-482", title: "title-635")
        #expect(item.status == Labs.ResultBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newResultBundle("code-482", title: "title-635")
        try item.moveTo(Labs.ResultBundleStatus.rejected)
        #expect(item.status == Labs.ResultBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newResultBundle("code-482", title: "title-635")
        item.status = Labs.ResultBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultBundleStatus.proposed) }
    }
}

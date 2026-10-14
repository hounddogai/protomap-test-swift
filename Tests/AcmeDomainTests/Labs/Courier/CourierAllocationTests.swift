@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAllocationTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCourierAllocation("code-387", title: "title-496")
        #expect(item.status == Labs.CourierAllocationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCourierAllocation("code-387", title: "title-496")
        try item.moveTo(Labs.CourierAllocationStatus.validated)
        #expect(item.status == Labs.CourierAllocationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCourierAllocation("code-387", title: "title-496")
        item.status = Labs.CourierAllocationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierAllocationStatus.created) }
    }
}

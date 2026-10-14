@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTemplateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierTemplate("code-906", label: "label-433")
        #expect(item.status == Labs.CourierTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newCourierTemplate("code-906", label: "label-433")
        try item.moveTo(Labs.CourierTemplateStatus.draining)
        #expect(item.status == Labs.CourierTemplateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierTemplate("code-906", label: "label-433")
        item.status = Labs.CourierTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierTemplateStatus.idle) }
    }
}

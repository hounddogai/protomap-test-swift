@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationTemplateTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLenientIsolationTemplate("code-605", title: "title-589")
        #expect(item.status == BedManagement.LenientIsolationTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newLenientIsolationTemplate("code-605", title: "title-589")
        try item.moveTo(BedManagement.LenientIsolationTemplateStatus.resolved)
        #expect(item.status == BedManagement.LenientIsolationTemplateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLenientIsolationTemplate("code-605", title: "title-589")
        item.status = BedManagement.LenientIsolationTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientIsolationTemplateStatus.`open`) }
    }
}

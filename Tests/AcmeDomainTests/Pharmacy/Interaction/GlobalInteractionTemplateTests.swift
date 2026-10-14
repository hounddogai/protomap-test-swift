@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInteractionTemplateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newGlobalInteractionTemplate("code-301", title: "title-880")
        #expect(item.status == Pharmacy.GlobalInteractionTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newGlobalInteractionTemplate("code-301", title: "title-880")
        try item.moveTo(Pharmacy.GlobalInteractionTemplateStatus.warming)
        #expect(item.status == Pharmacy.GlobalInteractionTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newGlobalInteractionTemplate("code-301", title: "title-880")
        item.status = Pharmacy.GlobalInteractionTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalInteractionTemplateStatus.idle) }
    }
}

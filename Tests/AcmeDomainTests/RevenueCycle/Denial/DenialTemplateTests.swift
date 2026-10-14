@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialTemplateTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialTemplate("code-459", title: "title-89")
        #expect(item.status == RevenueCycle.DenialTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newDenialTemplate("code-459", title: "title-89")
        try item.moveTo(RevenueCycle.DenialTemplateStatus.withdrawn)
        #expect(item.status == RevenueCycle.DenialTemplateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialTemplate("code-459", title: "title-89")
        item.status = RevenueCycle.DenialTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialTemplateStatus.proposed) }
    }
}

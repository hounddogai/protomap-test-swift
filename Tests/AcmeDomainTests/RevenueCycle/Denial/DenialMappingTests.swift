@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMappingTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDenialMapping("code-980", label: "label-140")
        #expect(item.status == RevenueCycle.DenialMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newDenialMapping("code-980", label: "label-140")
        try item.moveTo(RevenueCycle.DenialMappingStatus.failed)
        #expect(item.status == RevenueCycle.DenialMappingStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDenialMapping("code-980", label: "label-140")
        item.status = RevenueCycle.DenialMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialMappingStatus.new) }
    }
}

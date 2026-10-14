@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimRecordTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newLenientClaimRecord("code-254", label: "label-250")
        #expect(item.status == RevenueCycle.LenientClaimRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newLenientClaimRecord("code-254", label: "label-250")
        try item.moveTo(RevenueCycle.LenientClaimRecordStatus.granted)
        #expect(item.status == RevenueCycle.LenientClaimRecordStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newLenientClaimRecord("code-254", label: "label-250")
        item.status = RevenueCycle.LenientClaimRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientClaimRecordStatus.requested) }
    }
}

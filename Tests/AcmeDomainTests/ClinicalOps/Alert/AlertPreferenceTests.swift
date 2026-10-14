@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPreferenceTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertPreference("code-106", label: "label-226")
        #expect(item.status == ClinicalOps.AlertPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAlertPreference("code-106", label: "label-226")
        try item.moveTo(ClinicalOps.AlertPreferenceStatus.granted)
        #expect(item.status == ClinicalOps.AlertPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertPreference("code-106", label: "label-226")
        item.status = ClinicalOps.AlertPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertPreferenceStatus.requested) }
    }
}

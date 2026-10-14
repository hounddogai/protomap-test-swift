@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallBaselineTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRollingRecallBaseline("code-185", label: "label-964")
        #expect(item.status == Pharmacy.RollingRecallBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newRollingRecallBaseline("code-185", label: "label-964")
        try item.moveTo(Pharmacy.RollingRecallBaselineStatus.published)
        #expect(item.status == Pharmacy.RollingRecallBaselineStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRollingRecallBaseline("code-185", label: "label-964")
        item.status = Pharmacy.RollingRecallBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingRecallBaselineStatus.created) }
    }
}

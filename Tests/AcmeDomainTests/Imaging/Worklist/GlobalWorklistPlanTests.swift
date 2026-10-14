@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalWorklistPlanTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newGlobalWorklistPlan("code-684", label: "label-835")
        #expect(item.status == Imaging.GlobalWorklistPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newGlobalWorklistPlan("code-684", label: "label-835")
        try item.moveTo(Imaging.GlobalWorklistPlanStatus.validated)
        #expect(item.status == Imaging.GlobalWorklistPlanStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newGlobalWorklistPlan("code-684", label: "label-835")
        item.status = Imaging.GlobalWorklistPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalWorklistPlanStatus.created) }
    }
}

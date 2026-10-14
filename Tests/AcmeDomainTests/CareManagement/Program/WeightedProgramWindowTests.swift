@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramWindowTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newWeightedProgramWindow("code-473", label: "label-159")
        #expect(item.status == CareManagement.WeightedProgramWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newWeightedProgramWindow("code-473", label: "label-159")
        try item.moveTo(CareManagement.WeightedProgramWindowStatus.published)
        #expect(item.status == CareManagement.WeightedProgramWindowStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newWeightedProgramWindow("code-473", label: "label-159")
        item.status = CareManagement.WeightedProgramWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedProgramWindowStatus.created) }
    }
}

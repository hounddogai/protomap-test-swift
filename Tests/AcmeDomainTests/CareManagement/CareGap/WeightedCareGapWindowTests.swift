@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapWindowTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newWeightedCareGapWindow("code-731", label: "label-294")
        #expect(item.status == CareManagement.WeightedCareGapWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newWeightedCareGapWindow("code-731", label: "label-294")
        try item.moveTo(CareManagement.WeightedCareGapWindowStatus.resolved)
        #expect(item.status == CareManagement.WeightedCareGapWindowStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newWeightedCareGapWindow("code-731", label: "label-294")
        item.status = CareManagement.WeightedCareGapWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedCareGapWindowStatus.`open`) }
    }
}

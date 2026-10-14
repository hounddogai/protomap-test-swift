@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramEstimateTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newDefaultProgramEstimate("code-263", name: "name-849")
        #expect(item.status == CareManagement.DefaultProgramEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newDefaultProgramEstimate("code-263", name: "name-849")
        try item.moveTo(CareManagement.DefaultProgramEstimateStatus.withdrawn)
        #expect(item.status == CareManagement.DefaultProgramEstimateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newDefaultProgramEstimate("code-263", name: "name-849")
        item.status = CareManagement.DefaultProgramEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultProgramEstimateStatus.proposed) }
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRiskScoreAgreementEngine()
        let item = CareManagement.newRiskScoreAgreement("code-321", name: "name-783")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

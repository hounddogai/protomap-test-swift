@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultScheduledOutreachAgreementEngine()
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultPrimaryHandoffAgreementEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}

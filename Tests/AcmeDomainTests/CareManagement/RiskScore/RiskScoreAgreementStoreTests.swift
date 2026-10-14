@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreAgreementStore = CareManagement.newMemoryRiskScoreAgreementStore()
        let item = CareManagement.newRiskScoreAgreement("code-321", name: "name-783")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreDigestStore = CareManagement.newMemoryRiskScoreDigestStore()
        let item = CareManagement.newRiskScoreDigest("code-160", label: "label-516")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

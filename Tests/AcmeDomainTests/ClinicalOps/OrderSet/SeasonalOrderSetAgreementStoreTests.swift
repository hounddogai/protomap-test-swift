@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalOrderSetAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalOrderSetAgreementStore = ClinicalOps.newMemorySeasonalOrderSetAgreementStore()
        let item = ClinicalOps.newSeasonalOrderSetAgreement("code-331", label: "label-897")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

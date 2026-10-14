@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictTaskVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictTaskVarianceStore = ClinicalOps.newMemoryStrictTaskVarianceStore()
        let item = ClinicalOps.newStrictTaskVariance("code-281", name: "name-230")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

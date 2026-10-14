@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalHandoffExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalHandoffExceptionStore = ClinicalOps.newMemoryRegionalHandoffExceptionStore()
        let item = ClinicalOps.newRegionalHandoffException("code-483", name: "name-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

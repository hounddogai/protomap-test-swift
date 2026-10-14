@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingExceptionStore = ClinicalOps.newMemoryRoundingExceptionStore()
        let item = ClinicalOps.newRoundingException("code-827", name: "name-204")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

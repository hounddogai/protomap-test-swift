@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultCareProtocolExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultCareProtocolExceptionStore = ClinicalOps.newMemoryDefaultCareProtocolExceptionStore()
        let item = ClinicalOps.newDefaultCareProtocolException("code-337", title: "title-47")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

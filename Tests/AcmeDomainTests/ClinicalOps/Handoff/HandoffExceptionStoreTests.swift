@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffExceptionStore = ClinicalOps.newMemoryHandoffExceptionStore()
        let item = ClinicalOps.newHandoffException("code-22", title: "title-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

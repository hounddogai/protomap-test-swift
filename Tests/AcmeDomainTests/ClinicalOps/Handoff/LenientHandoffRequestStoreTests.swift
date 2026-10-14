@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientHandoffRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientHandoffRequestStore = ClinicalOps.newMemoryLenientHandoffRequestStore()
        let item = ClinicalOps.newLenientHandoffRequest("code-242", label: "label-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

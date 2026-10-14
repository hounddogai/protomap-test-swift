@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionEstimateStore = Labs.newMemoryAccessionEstimateStore()
        let item = Labs.newAccessionEstimate("code-150", label: "label-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultVarianceStore = Labs.newMemoryResultVarianceStore()
        let item = Labs.newResultVariance("code-517", title: "title-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

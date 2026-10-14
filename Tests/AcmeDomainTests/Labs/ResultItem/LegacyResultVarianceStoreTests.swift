@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyResultVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyResultVarianceStore = Labs.newMemoryLegacyResultVarianceStore()
        let item = Labs.newLegacyResultVariance("code-302", title: "title-740")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

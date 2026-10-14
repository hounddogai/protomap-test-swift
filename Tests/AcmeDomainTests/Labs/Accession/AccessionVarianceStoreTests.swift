@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionVarianceStore = Labs.newMemoryAccessionVarianceStore()
        let item = Labs.newAccessionVariance("code-249", name: "name-850")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

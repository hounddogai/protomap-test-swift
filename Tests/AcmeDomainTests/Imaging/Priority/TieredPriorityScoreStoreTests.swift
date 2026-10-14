@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredPriorityScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredPriorityScoreStore = Imaging.newMemoryTieredPriorityScoreStore()
        let item = Imaging.newTieredPriorityScore("code-697", name: "name-300")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalResultOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalResultOverrideStore = Labs.newMemorySeasonalResultOverrideStore()
        let item = Labs.newSeasonalResultOverride("code-354", title: "title-348")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

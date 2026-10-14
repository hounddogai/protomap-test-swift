@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalPanelScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalPanelScoreStore = Labs.newMemorySeasonalPanelScoreStore()
        let item = Labs.newSeasonalPanelScore("code-810", name: "name-327")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

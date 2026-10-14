@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalPanelWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalPanelWindowStore = Labs.newMemorySeasonalPanelWindowStore()
        let item = Labs.newSeasonalPanelWindow("code-781", name: "name-61")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

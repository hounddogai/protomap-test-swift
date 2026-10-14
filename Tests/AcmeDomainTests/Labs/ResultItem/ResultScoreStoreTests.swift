@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultScoreStore = Labs.newMemoryResultScoreStore()
        let item = Labs.newResultScore("code-944", name: "name-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

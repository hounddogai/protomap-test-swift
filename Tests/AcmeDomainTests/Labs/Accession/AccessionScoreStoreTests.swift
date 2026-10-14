@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionScoreStore = Labs.newMemoryAccessionScoreStore()
        let item = Labs.newAccessionScore("code-46", title: "title-598")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

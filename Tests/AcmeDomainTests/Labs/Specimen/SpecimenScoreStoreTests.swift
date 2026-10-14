@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenScoreStore = Labs.newMemorySpecimenScoreStore()
        let item = Labs.newSpecimenScore("code-329", name: "name-965")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

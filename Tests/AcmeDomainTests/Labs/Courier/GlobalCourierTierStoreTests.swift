@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalCourierTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalCourierTierStore = Labs.newMemoryGlobalCourierTierStore()
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionGroupStore = Labs.newMemoryAccessionGroupStore()
        let item = Labs.newAccessionGroup("code-617", label: "label-386")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

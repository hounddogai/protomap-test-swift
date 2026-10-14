@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryAccessionGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryAccessionGroupStore = Labs.newMemoryPrimaryAccessionGroupStore()
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

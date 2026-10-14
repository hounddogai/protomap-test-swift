@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedCourierProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedCourierProfileStore = Labs.newMemoryCappedCourierProfileStore()
        let item = Labs.newCappedCourierProfile("code-445", label: "label-662")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
